// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileTransfer.h"
#include "DataHelpers.h"
#include <string>

namespace Passepartout {
std::string TransferText(const Models::ProfileTransfer &transfer, NumberFormatter formatter = {});
}
