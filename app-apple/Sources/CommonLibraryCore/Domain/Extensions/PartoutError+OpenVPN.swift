// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public extension PartoutError {
    var isOpenVPNPassphraseRequired: Bool {
        guard code == .openVPN, let subCode = subCode.flatMap(OpenVPNErrorCode.init(rawValue:)) else {
            return false
        }
        return [.passphraseRequired, .unableToDecrypt].contains(subCode)
    }
}
