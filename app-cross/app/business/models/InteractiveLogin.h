// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "Profile.h"

namespace Passepartout {
struct InteractiveLogin {
    Profile original;
    Partout::Models::OpenVpnCredentials credentials;
    bool needs_otp = false;
    static std::optional<InteractiveLogin> FromProfile(const Profile &profile);
    bool CanSubmit() const;
};
}
