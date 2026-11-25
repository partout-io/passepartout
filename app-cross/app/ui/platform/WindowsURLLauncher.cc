// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "WindowsURLLauncher.h"
#include <chrono>
#include <roapi.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.System.h>

namespace Passepartout {
using namespace winrt::Windows::Foundation;
struct WindowsURLLauncher::Impl {
    struct Apartment {
        Apartment() {
            winrt::check_hresult(RoInitialize(RO_INIT_SINGLETHREADED));
        }

        ~Apartment() {
            RoUninitialize();
        }
    } apartment;
    IAsyncOperation<bool> operation{nullptr};
    const std::chrono::steady_clock::time_point deadline =
        std::chrono::steady_clock::now() + std::chrono::seconds(30);
    explicit Impl(const std::string &url) {
        const Uri uri(winrt::to_hstring(url));
        if (uri.SchemeName() != L"https" || uri.Host().empty()) throw winrt::hresult_invalid_argument();
        // The system broker can launch outside AppContainer; ShellExecute cannot
        // reliably resolve the user's browser association from this process.
        operation = winrt::Windows::System::Launcher::LaunchUriAsync(uri);
    }

    ~Impl() {
        try {
            if (operation && operation.Status() == AsyncStatus::Started) operation.Cancel();
        } catch (...) {}
    }
};
WindowsURLLauncher::WindowsURLLauncher(const std::string &url) : impl_(std::make_unique<Impl>(url)) {}

WindowsURLLauncher::~WindowsURLLauncher() = default;

std::optional<bool> WindowsURLLauncher::Poll() {
    if (impl_->operation.Status() != AsyncStatus::Started) return impl_->operation.GetResults();
    if (std::chrono::steady_clock::now() < impl_->deadline) return {};
    impl_->operation.Cancel();
    return false;
}
}
