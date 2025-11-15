// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources

extension HTTPAddressPort {
    var urlDescription: String? {
        let addressDescription = {
            !address.isEmpty ? address : "<\(Strings.Global.Nouns.address.lowercased())>"
        }
        guard let port = Int(port) else {
            let portDescription = "<\(Strings.Global.Nouns.port.lowercased())>"
            return "\(scheme)://\(addressDescription()):\(portDescription)"
        }
        guard !address.isEmpty else {
            return "\(scheme)://\(addressDescription()):\(port)"
        }
        return url?.absoluteString
    }
}

extension HTTPAddressPort {
    static var forWebReceiver: HTTPAddressPort {
        HTTPAddressPort(port: String(Resources.constants.webReceiver.port))
    }
}
