// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public extension PartoutError {
    var parseErrorInfo: ParseErrorInfo? {
        guard code == .parsing, let payload,
              let data = try? JSONEncoder.shared().encode(payload) else {
            return nil
        }
        return try? JSONDecoder.shared().decode(ParseErrorInfo.self, from: data)
    }

    var isOpenVPNPassphraseRequired: Bool {
        guard let info = parseErrorInfo, info.recognizedType == .OpenVPN,
              let subCode = info.subCode.flatMap(OpenVPNErrorCode.init(rawValue:)) else {
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
