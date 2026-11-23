// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#pragma once
#include "ProfileTransfer.h"
#include "FormatDataUnit.h"
#include <string>

namespace Passepartout::Profiles {
std::string TransferText(const Models::ProfileTransfer &transfer, DataUnits::NumberFormatter formatter = {});
}
