// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#include "app_profile.h"
#include "data_helpers.h"

namespace Passepartout {
std::string TransferText(const Models::ProfileTransfer &transfer) {
    return "\xe2\x86\x93" + FormatDataUnit(transfer.received) +
           " \xe2\x86\x91" + FormatDataUnit(transfer.sent);
}
}
