// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <wx/window.h>
#include <wx/timer.h>

namespace Passepartout {
// Owned by the requesting view. Polls on the UI thread and destroys itself
// after completion; closing the view cancels the native request.
class WindowsURLLauncher final : public wxWindow {
public:
    WindowsURLLauncher(
        wxWindow *parent, const std::string &url, std::function<void(wxWindow *)> on_error
    );
    ~WindowsURLLauncher() override;
private:
    std::optional<bool> Poll();
    void OnTimer(wxTimerEvent &event);
    struct Impl;
    std::unique_ptr<Impl> impl_;
    wxTimer timer_;
    std::function<void(wxWindow *)> on_error_;
};
}
