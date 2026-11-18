// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <string>

namespace Passepartout {
class WireGuardKeyGenerator {
public:
    virtual ~WireGuardKeyGenerator() = default;
    virtual std::string PublicKey(const std::string &privateKey) const = 0;
};
}
