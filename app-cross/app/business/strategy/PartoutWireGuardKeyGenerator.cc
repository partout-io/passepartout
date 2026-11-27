// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PartoutWireGuardKeyGenerator.h"
#include <partout/Runtime.h>

namespace Passepartout {
std::string PartoutWireGuardKeyGenerator::PublicKey(const std::string &private_key) const {
    return Partout::Runtime::WireGuardPublicKey(private_key).value_or(std::string());
}
}
