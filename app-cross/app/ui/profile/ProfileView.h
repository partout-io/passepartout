// SPDX-FileCopyrightText: 2026 Davide De Rosa
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../../business/managers/ProfileEditor.h"
#include "../theme/ThemeDetailView.h"
#include <functional>
#include <memory>

namespace Passepartout {
class ProfileView final : public ThemeDetailView {
public:
    ProfileView(wxWindow *parent, std::shared_ptr<ProfileEditor> editor,
                std::function<void()> changed);
};
}
