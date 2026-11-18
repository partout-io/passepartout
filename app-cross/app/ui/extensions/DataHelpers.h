// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include <cstdint>
#include <string>
#include <functional>

namespace Passepartout {
using NumberFormatter = std::function<std::string(double, int)>;
std::string FormatDataUnit(int64_t bytes, NumberFormatter formatter = {});
}
