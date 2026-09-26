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
            return parsingDescription()
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
            if specific == .unsupportedCompression {
                return Strings.Errors.Openvpn.unsupportedCompression
            }
            return specific?.localizedConnectionDescription ?? Strings.Errors.Tunnel.generic
        case .wireGuard:
            if pair.subCode.flatMap(WireGuardErrorCode.init(rawValue:)) == .emptyPeers {
                return Strings.Errors.Wireguard.emptyPeers
            }
            return Strings.Errors.Tunnel.generic
        default:
            return Strings.Errors.Tunnel.generic
        }
    }

    func parsingDescription() -> String {
        guard let info = parseErrorInfo else {
            return Strings.Errors.App.parsing
        }
        switch info.recognizedType {
        case .OpenVPN:
            switch info.subCode.flatMap(OpenVPNErrorCode.init(rawValue:)) {
            case .passphraseRequired, .unableToDecrypt:
                // The importer handles these errors with a passphrase prompt.
                return Strings.Errors.App.other
            case .unsupportedCompression:
                return Strings.Errors.Openvpn.unsupportedCompression
            default:
                return Strings.Errors.App.parsing
            }
        case .WireGuard:
            return wireGuardParsingDescription(
                code: info.subCode.flatMap(WireGuardErrorCode.init(rawValue:)),
                argument: info.arguments.first ?? "?"
            ) ?? Strings.Errors.App.parsing
        default:
            return Strings.Errors.App.parsing
        }
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
