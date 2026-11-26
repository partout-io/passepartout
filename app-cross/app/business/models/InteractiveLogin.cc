// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "InteractiveLogin.h"

namespace Passepartout {
bool InteractiveLogin::CanSubmit() const {
    const auto &value = needs_otp ? credentials.password : credentials.username;
    return value.find_first_not_of(" \t\r\n") != std::string::npos;
}
}
