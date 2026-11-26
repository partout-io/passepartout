// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigurationPicker.h"
#include <windows.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.h>
#include <mutex>

namespace Passepartout::Windows {
// The owner must outlive the picker. Construct and start on its UI thread.
class ConfigurationPicker final : public Passepartout::ConfigurationPicker {
public:
    explicit ConfigurationPicker(HWND owner);
    ~ConfigurationPicker() override;
    void Start() override;
    std::optional<ConfigurationPickerResult> Poll() override;
    void Cancel() override;
private:
    struct SelectionState final {
        std::mutex mutex;
        bool cancelled = false;
        std::optional<ConfigurationPickerResult> result;
        void Finish(ConfigurationPickerResult value);
    };
    const HWND owner_;
    std::shared_ptr<SelectionState> state_;
    winrt::Windows::Foundation::IAsyncOperation<winrt::Windows::Foundation::Collections::IVectorView<winrt::Windows::Storage::StorageFile>> operation_{nullptr};
};
}
