// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppProfile.h"
#include "FormatDataUnit.h"

namespace Passepartout {
std::string Profiles::TransferText(const Models::ProfileTransfer &transfer, DataUnits::NumberFormatter formatter) {
    return "\xe2\x86\x93" + DataUnits::Format(transfer.received, formatter) +
           " \xe2\x86\x91" + DataUnits::Format(transfer.sent, formatter);
}
}
