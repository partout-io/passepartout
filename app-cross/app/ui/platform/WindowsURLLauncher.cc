// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#include "WindowsURLLauncher.h"
#include <wx/weakref.h>
#include <chrono>
#include <utility>
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

WindowsURLLauncher::WindowsURLLauncher(
    wxWindow *parent, const std::string &url, std::function<void(wxWindow *)> on_error
) : wxWindow(parent, wxID_ANY), impl_(std::make_unique<Impl>(url)), timer_(this),
    on_error_(std::move(on_error)) {
    Hide();
    Bind(wxEVT_TIMER, &WindowsURLLauncher::OnTimer, this);
    timer_.Start(50);
}

WindowsURLLauncher::~WindowsURLLauncher() = default;

void WindowsURLLauncher::OnTimer(wxTimerEvent &) {
    std::optional<bool> result;
    try {
        result = Poll();
    } catch (...) {
        result = false;
    }
    if (!result) return;
    timer_.Stop();
    // The callback may run a nested event loop and destroy this window.
    const wxWeakRef<wxWindow> target(this);
    auto on_error = std::move(on_error_);
    if (!*result && on_error) on_error(GetParent());
    if (target) target->Destroy();
}

std::optional<bool> WindowsURLLauncher::Poll() {
    if (impl_->operation.Status() != AsyncStatus::Started) return impl_->operation.GetResults();
    if (std::chrono::steady_clock::now() < impl_->deadline) return {};
    impl_->operation.Cancel();
    return false;
}
}
