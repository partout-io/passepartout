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

extension PartoutErrorPair {
    public static func openVPN(_ code: OpenVPNErrorCode) -> Self {
        Self(code: .openVPN, subCode: code.rawValue)
    }

    public static func wireGuard(_ code: WireGuardErrorCode) -> Self {
        Self(code: .wireGuard, subCode: code.rawValue)
    }
}
