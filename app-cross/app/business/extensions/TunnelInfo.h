// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "AppTunnelInfo.h"
#include <partout/models/TunnelSnapshot.h>

namespace Passepartout {
using Status = Models::AppProfileStatus::eAppProfileStatus;
namespace Tunnels {
std::vector<Models::AppTunnelInfo> Info(const std::vector<Partout::Models::TunnelSnapshot> &snapshots);
}
}
