// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension IAPManager {
    public var verificationDelayMinutes: Int {
        Constants.shared.tunnel.verificationDelayMinutes(isBeta: isBeta)
    }
}
