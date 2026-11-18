// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "AppProfile.h"
#include "DataHelpers.h"

namespace Passepartout {
std::string TransferText(const Models::ProfileTransfer &transfer, NumberFormatter formatter) {
    return "\xe2\x86\x93" + FormatDataUnit(transfer.received, formatter) +
           " \xe2\x86\x91" + FormatDataUnit(transfer.sent, formatter);
}
}
