// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources

extension IAPManager {
    public var verificationDelayMinutes: Int {
        Resources.constants.tunnel.verificationDelayMinutes(isBeta: isBeta)
    }
}
