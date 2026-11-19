// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "InteractiveLogin.h"
#include <algorithm>

namespace Passepartout {
std::optional<InteractiveLogin> InteractiveLogin::FromProfile(const Profile &profile) {
    for (const auto &tagged : profile.modules) {
        const auto *openvpn = std::get_if<Partout::Models::TaggedModuleOpenVpn>(&tagged);
        if (!openvpn) continue;
        const auto &module = openvpn->value;
        if (std::find(profile.activeModulesIds.begin(), profile.activeModulesIds.end(), module.id) == profile.activeModulesIds.end()) continue;
        const auto &saved = module.credentials;
        const bool missing = !saved || (saved->username.empty() && saved->password.empty());
        if (!module.requiresInteractiveCredentials.value_or(false) &&
            !(module.configuration && (module.configuration->staticChallenge.value_or(false) ||
                (module.configuration->authUserPass.value_or(false) && missing)))) continue;
        InteractiveLogin login{};
        login.original = profile;
        login.credentials.otpMethod.value = Partout::Models::OpenVpnCredentialsOTPMethod::none;
        if (saved) login.credentials = *saved;
        login.needsOTP = login.credentials.otpMethod.value != Partout::Models::OpenVpnCredentialsOTPMethod::none;
        // The native adapter receives the raw OTP; Partout applies its encoding.
        if (login.needsOTP) login.credentials.password.clear();
        login.credentials.otp.reset();
        return login;
    }
    return std::nullopt;
}
bool InteractiveLogin::CanSubmit() const {
    const auto &value = needsOTP ? credentials.password : credentials.username;
    return value.find_first_not_of(" \t\r\n") != std::string::npos;
}
}
