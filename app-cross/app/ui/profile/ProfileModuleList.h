// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../theme/ThemeList.h"
#include "../../observables/ProfileEditor.h"
#include <functional>

namespace Passepartout {
class ProfileModuleList final : public ThemeList {
public:
    // Selection 0 is General; other selections are the original module index + 1.
    ProfileModuleList(wxWindow *parent, const ProfileEditor &editor,
        std::function<void(std::size_t)> selected);
private:
    void UpdateMetrics();
    unsigned selectedRow_ = 0;
};
}
