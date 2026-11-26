// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "WireGuardKeyGenerator.h"

namespace Passepartout {
class PartoutWireGuardKeyGenerator final : public WireGuardKeyGenerator {
public:
    std::string PublicKey(const std::string &private_key) const override;
};
}
