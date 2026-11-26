// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <partout/models/TaggedProfile.h>
#include <partout/tunnel/TunnelCredentials.h>

namespace Passepartout {
struct InteractiveLogin {
    Partout::Models::TaggedProfile original;
    Partout::TunnelCredentials credentials;
    bool needs_otp = false;
    bool CanSubmit() const;
};
}
