// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ConfigBundleConfig.h"
#include "ConfigFlag.h"
#include <map>

namespace Passepartout {
using ConfigBundle = std::map<Models::ConfigFlag::eConfigFlag, Models::ConfigBundleConfig>;
}
