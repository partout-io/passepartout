// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "../business/tunnel_strategy.h"

namespace Passepartout {
std::unique_ptr<TunnelStrategy> MakeWindowsTunnelStrategy(const std::string &serverUri,
                                                        std::vector<std::string> dnsFallbackServers);
}
