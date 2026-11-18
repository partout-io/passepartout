// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../observables/ProfileEditor.h"
#include <wx/panel.h>
#include <functional>
#include <memory>

namespace Passepartout {
class ThemeList;
class ProfileView final : public wxPanel {
public:
    ProfileView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor,
                std::function<void(std::size_t)> openModule, std::function<void()> changed);
private:
    void UpdateMetrics();
    void ResizeColumns();
    ThemeList *modules_;
    int statusWidth_ = 0;
};
}
