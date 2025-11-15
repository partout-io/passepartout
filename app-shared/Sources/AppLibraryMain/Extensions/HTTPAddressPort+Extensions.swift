// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources

extension ABI.HTTPAddressPort {
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

extension ABI.HTTPAddressPort {
    static var forWebReceiver: ABI.HTTPAddressPort {
        ABI.HTTPAddressPort(port: String(Resources.constants.webReceiver.port))
    }
}
