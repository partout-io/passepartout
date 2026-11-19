// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "WindowsConfigurationPicker.h"
#include "../ui/extensions/ConfigurationSelection.h"
#include <shobjidl.h>
#include <roapi.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Pickers.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.System.Threading.h>
#include <mutex>

namespace Passepartout {
namespace {
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Storage;
constexpr wchar_t ImportFolder[] = L"configuration-imports";
constexpr std::uint32_t MaxBytes = 1024 * 1024;

struct RequestDirectory {
    explicit RequestDirectory(std::filesystem::path value) : path(std::move(value)) {}
    ~RequestDirectory() {
        // The path is constructed locally from a generated ID.
        std::error_code error;
        std::filesystem::remove_all(path, error);
    }
    const std::filesystem::path path;
};
struct StagedFiles final : ConfigurationFiles {
    StagedFiles(ConfigurationFiles files, std::shared_ptr<RequestDirectory> owner)
        : ConfigurationFiles(std::move(files.paths), files.selectionFailures), directory(std::move(owner)) {}
    const std::shared_ptr<RequestDirectory> directory;
};
struct SelectionState {
    std::mutex mutex;
    bool cancelled = false;
    std::optional<ConfigurationPickerResult> result;

    void Finish(ConfigurationPickerResult value) {
        std::lock_guard lock(mutex);
        if (!cancelled) result = std::move(value);
    }
};

std::wstring NewRequestId() {
    GUID identifier{};
    winrt::check_hresult(CoCreateGuid(&identifier));
    wchar_t text[39]{};
    if (!StringFromGUID2(identifier, text, 39)) throw std::runtime_error("Cannot create import request.");
    return text;
}

ConfigurationPickerResult Collect(const Collections::IVectorView<StorageFile> &files, const std::wstring &request,
                                  const std::shared_ptr<RequestDirectory> &directory) {
    if (!files || !files.Size()) return {};
    const auto count = files.Size();
    const auto root = ApplicationData::Current().TemporaryFolder().CreateFolderAsync(
        ImportFolder, CreationCollisionOption::OpenIfExists).get();
    const auto destination = root.CreateFolderAsync(request, CreationCollisionOption::FailIfExists).get();
    auto selected = CollectConfigurationFiles(count, [&](std::size_t index) {
        const auto file = files.GetAt(static_cast<std::uint32_t>(index));
        const auto stream = file.OpenReadAsync().get();
        if (!stream.Size() || stream.Size() > MaxBytes) throw std::runtime_error("Invalid import file size.");
        const auto buffer = stream.ReadAsync(Streams::Buffer(MaxBytes + 1),
            MaxBytes + 1, Streams::InputStreamOptions::None).get();
        if (!buffer.Length() || buffer.Length() > MaxBytes) throw std::runtime_error("Invalid import file size.");
        const auto folder = destination.CreateFolderAsync(std::to_wstring(index)).get();
        const auto copy = folder.CreateFileAsync(file.Name()).get();
        FileIO::WriteBufferAsync(copy, buffer).get();
        return std::filesystem::path(copy.Path().c_str());
    });
    return {std::make_shared<StagedFiles>(std::move(selected), directory), false};
}

class WindowsConfigurationPicker final : public ConfigurationPicker {
public:
    explicit WindowsConfigurationPicker(HWND owner) : owner_(owner) {}
    ~WindowsConfigurationPicker() override {
        Cancel();
    }
    void Start() override {
        Cancel();
        state_ = std::make_shared<SelectionState>();
        const auto state = state_;
        try {
            // Balance WinRT initialization on the owner's STA thread.
            winrt::check_hresult(RoInitialize(RO_INIT_SINGLETHREADED));
            struct Apartment {
                ~Apartment() {
                    RoUninitialize();
                }
            } apartment;
            const auto request = NewRequestId();
            const auto temporary = ApplicationData::Current().TemporaryFolder().Path();
            auto directory = std::make_shared<RequestDirectory>(
                std::filesystem::path(temporary.c_str()) / ImportFolder / request);
            // Use the owner's native window without depending on its UI toolkit.
            Pickers::FileOpenPicker picker;
            winrt::check_hresult(picker.as<IInitializeWithWindow>()->Initialize(owner_));
            picker.FileTypeFilter().Append(L"*");
            operation_ = picker.PickMultipleFilesAsync();
            operation_.Completed([state, directory, request](const auto &completed, auto) {
                // Completion may run on the STA. Keep filesystem I/O off the UI
                // thread and never capture the picker or its owner in callbacks.
                try {
                    winrt::Windows::System::Threading::ThreadPool::RunAsync([state, directory, request, completed](auto) {
                        try {
                            state->Finish(Collect(completed.GetResults(), request, directory));
                        } catch (...) {
                            state->Finish({nullptr, true});
                        }
                    });
                } catch (...) {
                    state->Finish({nullptr, true});
                }
            });
        } catch (...) {
            state->Finish({nullptr, true});
        }
    }
    std::optional<ConfigurationPickerResult> Poll() override {
        if (!state_) return std::nullopt;
        std::optional<ConfigurationPickerResult> result;
        {
            std::lock_guard lock(state_->mutex);
            result = std::move(state_->result);
            state_->result.reset();
        }
        if (result) operation_ = nullptr;
        return result;
    }
    void Cancel() override {
        if (state_) {
            std::lock_guard lock(state_->mutex);
            state_->cancelled = true;
            state_->result.reset();
        }
        if (operation_) {
            try {
                operation_.Cancel();
            } catch (...) {}
            operation_ = nullptr;
        }
        state_.reset();
    }
private:
    const HWND owner_;
    std::shared_ptr<SelectionState> state_;
    IAsyncOperation<Collections::IVectorView<StorageFile>> operation_{nullptr};
};
}

std::unique_ptr<ConfigurationPicker> MakeWindowsConfigurationPicker(HWND owner) {
    return std::make_unique<WindowsConfigurationPicker>(owner);
}
}
