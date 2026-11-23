// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "FileActivation.h"
#ifdef _WIN32
#include <windows.h>
#include <appmodel.h>
#include <future>
#include <atomic>
#include <thread>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.ApplicationModel.Activation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>
#endif

namespace Passepartout {
#ifdef _WIN32
namespace {
constexpr wchar_t WindowClass[] = L"Passepartout.FileActivation.1";
constexpr ULONG_PTR MessageType = 0x50504143;
struct Apartment {
    explicit Apartment(winrt::apartment_type type) {
        winrt::init_apartment(type);
    }
    ~Apartment() {
        winrt::uninit_apartment();
    }
};
template<typename Operation>
auto Await(const Operation &operation, const std::atomic_bool &canceled) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
    while (operation.Status() == winrt::Windows::Foundation::AsyncStatus::Started) {
        if (canceled.load() || std::chrono::steady_clock::now() >= deadline) {
            operation.Cancel();
            throw std::runtime_error("File activation timed out.");
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
    }
    return operation.GetResults();
}
class BrokeredFiles final : public ConfigurationFiles {
public:
    explicit BrokeredFiles(std::vector<winrt::Windows::Storage::StorageFile> files, std::size_t failures)
        : ConfigurationFiles({}, failures), files_(std::move(files)) {}
    std::size_t Count() const override {
        return files_.size();
    }
    ConfigurationSource Read(std::size_t index) const override {
        if (canceled_.load()) throw std::runtime_error("File activation canceled.");
        const Apartment apartment(winrt::apartment_type::multi_threaded);
        using namespace winrt::Windows::Storage::Streams;
        const auto &file = files_.at(index);
        const auto stream = Await(file.OpenReadAsync(), canceled_);
        constexpr uint32_t maximum = 1024 * 1024;
        if (!stream.Size() || stream.Size() > maximum) throw std::runtime_error("Invalid activation file size.");
        const auto buffer = Await(stream.ReadAsync(Buffer(maximum + 1), maximum + 1, InputStreamOptions::None), canceled_);
        if (!buffer.Length() || buffer.Length() > maximum) throw std::runtime_error("Invalid activation file size.");
        const auto name = std::filesystem::path(file.Name().c_str()).stem().wstring();
        return {winrt::to_string(name), std::string(reinterpret_cast<const char *>(buffer.data()), buffer.Length())};
    }
    void Cancel() const noexcept override {
        canceled_.store(true);
    }
private:
    const std::vector<winrt::Windows::Storage::StorageFile> files_;
    mutable std::atomic_bool canceled_{false};
};
bool IsSameExecutable(HWND window, DWORD &pid) {
    GetWindowThreadProcessId(window, &pid);
    const winrt::handle process(OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid));
    if (!process) return false;
    std::wstring current(32768, L'\0'), target(32768, L'\0');
    const auto count = GetModuleFileNameW(nullptr, current.data(), static_cast<DWORD>(current.size()));
    DWORD length = static_cast<DWORD>(target.size());
    if (!count || count == current.size() || !QueryFullProcessImageNameW(process.get(), 0, target.data(), &length)) return false;
    return CompareStringOrdinal(current.data(), count, target.data(), length, TRUE) == CSTR_EQUAL;
}
}
struct FileActivation::Impl {
    FileActivationInbox inbox;
    FileActivationInbox::Handler handler;
    HWND window = nullptr;
    static LRESULT CALLBACK WindowProcedure(HWND window, UINT message, WPARAM parameter, LPARAM data) {
        if (message == WM_NCCREATE) {
            const auto *creation = reinterpret_cast<CREATESTRUCTW *>(data);
            SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(creation->lpCreateParams));
        }
        auto *self = reinterpret_cast<Impl *>(GetWindowLongPtrW(window, GWLP_USERDATA));
        if (message == WM_COPYDATA && self) {
            const auto *copy = reinterpret_cast<COPYDATASTRUCT *>(data);
            if (!copy || copy->dwData != MessageType || !copy->lpData || copy->cbData > FileActivationInbox::MaximumBytes) return FALSE;
            try {
                return self->inbox.Accept(std::string(static_cast<const char *>(copy->lpData), copy->cbData), self->handler);
            } catch (...) {
                return FALSE;
            }
        }
        return DefWindowProcW(window, message, parameter, data);
    }
    Impl(const std::wstring &service, FileActivationInbox::Handler on_files) : handler(std::move(on_files)) {
        WNDCLASSW type{};
        type.hInstance = GetModuleHandleW(nullptr);
        type.lpszClassName = WindowClass;
        type.lpfnWndProc = WindowProcedure;
        if (!RegisterClassW(&type) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) throw std::runtime_error("Unable to register activation window.");
        window = CreateWindowExW(0, WindowClass, service.c_str(), 0, 0, 0, 0, 0, HWND_MESSAGE,
            nullptr, type.hInstance, this);
        if (!window) throw std::runtime_error("Unable to receive file activation.");
    }
    ~Impl() {
        if (window) DestroyWindow(window);
    }
};
FileActivation::FileActivation(const std::string &service, FileActivationInbox::Handler handler)
    : impl_(std::make_unique<Impl>(std::wstring(winrt::to_hstring(service).c_str()), std::move(handler))) {}
bool FileActivation::Forward(const std::string &service, std::shared_ptr<const ConfigurationFiles> files) {
    try {
        GUID uuid{};
        winrt::check_hresult(CoCreateGuid(&uuid));
        const auto id = winrt::to_string(winrt::to_hstring(uuid));
        // Read brokered files on an MTA, then transfer a copy before the sender exits.
        const auto message = std::async(std::launch::async, [id, files] {
            return FileActivationInbox::Encode(id, *files);
        }).get();
        const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(5);
        do {
            const auto window = FindWindowExW(HWND_MESSAGE, nullptr, WindowClass, winrt::to_hstring(service).c_str());
            DWORD pid = 0;
            if (window && IsSameExecutable(window, pid)) {
                AllowSetForegroundWindow(pid);
                COPYDATASTRUCT copy{};
                copy.dwData = MessageType;
                copy.cbData = static_cast<DWORD>(message.size());
                copy.lpData = const_cast<char *>(message.data());
                DWORD_PTR accepted = 0;
                if (SendMessageTimeoutW(window, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&copy),
                    SMTO_ABORTIFHUNG | SMTO_BLOCK, 1000, &accepted) && accepted) return true;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        } while (std::chrono::steady_clock::now() < deadline);
    } catch (...) {}
    return false;
}
std::shared_ptr<const ConfigurationFiles> FileActivation::ReadFiles() {
    UINT32 size = 0;
    if (GetCurrentPackageFullName(&size, nullptr) == APPMODEL_ERROR_NO_PACKAGE) return {};
    const Apartment apartment(winrt::apartment_type::single_threaded);
    using namespace winrt::Windows::ApplicationModel;
    const auto args = AppInstance::GetActivatedEventArgs();
    if (!args || args.Kind() != Activation::ActivationKind::File) return {};
    const auto items = args.as<Activation::IFileActivatedEventArgs>().Files();
    if (items.Size() > 64) throw std::runtime_error("Too many activation files.");
    std::vector<winrt::Windows::Storage::StorageFile> files;
    std::size_t failures = 0;
    for (const auto &item : items) {
        const auto file = item.try_as<winrt::Windows::Storage::StorageFile>();
        if (file) files.push_back(file);
        else ++failures;
    }
    return std::make_shared<BrokeredFiles>(std::move(files), failures);
}
#else
struct FileActivation::Impl {};
FileActivation::FileActivation(const std::string &, FileActivationInbox::Handler) {}
bool FileActivation::Forward(const std::string &, std::shared_ptr<const ConfigurationFiles>) {
    return false;
}
std::shared_ptr<const ConfigurationFiles> FileActivation::ReadFiles() {
    return {};
}
#endif
FileActivation::~FileActivation() = default;
}
