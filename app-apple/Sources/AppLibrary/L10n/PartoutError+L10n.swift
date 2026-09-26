// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppStrings
import CommonLibrary
import Partout

extension PartoutError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch code {
        case .openVPN, .wireGuard:
            return protocolDescription()
        case .parsing:
            return Strings.Errors.App.parsing
        case .unknownImportedModule:
            return Strings.Errors.App.parsing
        default:
            return Strings.Errors.App.partout(code.rawValue)
        }
    }
}

private extension PartoutError {
    func protocolDescription() -> String {
        let pair = errorPair
        switch pair.code {
        case .openVPN:
            let specific = pair.subCode.flatMap(OpenVPNErrorCode.init(rawValue:))
            if isOpenVPNPassphraseRequired {
                // The importer handles these errors with a passphrase prompt.
                return Strings.Errors.App.other
            }
            if specific == .unsupportedCompression {
                return Strings.Errors.Openvpn.unsupportedCompression
            }
            return specific?.localizedConnectionDescription ?? Strings.Errors.App.parsing
        case .wireGuard:
            return wireGuardParsingDescription(
                code: pair.subCode.flatMap(WireGuardErrorCode.init(rawValue:)),
                argument: parseErrorInfo?.arguments.first ?? "?"
            ) ?? Strings.Errors.App.parsing
        default:
            return Strings.Errors.App.parsing
        }
    }

    var parseErrorInfo: ParseErrorInfo? {
        guard let payload, let data = try? JSONEncoder.shared().encode(payload) else {
            return nil
        }
        return try? JSONDecoder.shared().decode(ParseErrorInfo.self, from: data)
    }

    func wireGuardParsingDescription(code: WireGuardErrorCode?, argument: String) -> String? {
        let V = Strings.Errors.Wireguard.self
        switch code {
        case .emptyPeers:
            return V.emptyPeers
        case .interfaceHasInvalidAddress:
            return V.Interface.Address.invalid(argument)
        case .interfaceHasInvalidDNS:
            return V.Interface.Dns.invalid(argument)
        case .interfaceHasInvalidListenPort:
            return V.Interface.ListenPort.invalid(argument)
        case .interfaceHasInvalidMTU:
            return V.Interface.Mtu.invalid(argument)
        case .interfaceHasInvalidPrivateKey:
            return V.Interface.PrivateKey.invalid
        case .interfaceHasNoPrivateKey:
            return V.Interface.PrivateKey.required
        case .interfaceHasUnrecognizedKey:
            return V.Interface.unrecognizedKey(argument)
        case .multipleEntriesForKey:
            return V.multipleEntriesForKey(argument)
        case .multipleInterfaces:
            return V.multipleInterfaces
        case .multiplePeersWithSamePublicKey:
            return V.Peer.PublicKey.duplicated
        case .noInterface:
            return V.noInterface
        case .peerHasInvalidAllowedIP:
            return V.Peer.AllowedIps.invalid(argument)
        case .peerHasInvalidEndpoint:
            return V.Peer.Endpoint.invalid(argument)
        case .peerHasInvalidPersistentKeepAlive:
            return V.Peer.PersistentKeepalive.invalid(argument)
        case .peerHasInvalidPreSharedKey:
            return V.Peer.PreSharedKey.invalid
        case .peerHasInvalidPublicKey:
            return V.Peer.PublicKey.invalid
        case .peerHasNoPublicKey:
            return V.Peer.PublicKey.required
        case .peerHasUnrecognizedKey:
            return V.Peer.unrecognizedKey(argument)
        case nil:
            return nil
        }
    }
}
