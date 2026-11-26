// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "PartoutWireGuardKeyGenerator.h"
#include "partout.h"
#include <cstdlib>
#include <memory>

namespace Passepartout {
std::string PartoutWireGuardKeyGenerator::PublicKey(const std::string &private_key) const {
    std::unique_ptr<char, decltype(&std::free)> key(partout_wireguard_pubkey(private_key.c_str()), &std::free);
    return key ? std::string(key.get()) : std::string();
}
}
