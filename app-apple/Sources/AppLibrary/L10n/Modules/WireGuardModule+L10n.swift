// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

extension WireGuardParseError: @retroactive LocalizedError {
    public var errorDescription: String? {
        let V = Strings.Errors.Wireguard.self
        switch self {
        case .invalidLine(let line):
            return V.Title.invalidLine(line)
        case .noInterface:
            return V.Title.noInterface
        case .multipleInterfaces:
            return V.Title.multipleInterfaces
        case .interfaceHasNoPrivateKey:
            return composed(V.Interface.messagePrivateKeyRequired, V.Interface.messagePrivateKeyInvalid)
        case .interfaceHasInvalidPrivateKey:
            return composed(V.Title.privateKeyInvalid, V.Interface.messagePrivateKeyInvalid)
        case .interfaceHasInvalidListenPort(let value):
            return composed(V.Title.listenPortInvalid(value), V.Interface.messageListenPortInvalid)
        case .interfaceHasInvalidAddress(let value):
            return composed(V.Title.addressInvalid(value), V.Interface.messageAddressInvalid)
        case .interfaceHasInvalidDNS(let value):
            return composed(V.Title.dnsInvalid(value), V.Interface.messageDNSInvalid)
        case .interfaceHasInvalidMTU(let value):
            return composed(V.Title.mtuInvalid(value), V.Interface.messageMTUInvalid)
        case .interfaceHasUnrecognizedKey(let value):
            return composed(V.Title.unrecognizedInterfaceKey(value), V.Title.infoUnrecognizedInterfaceKey)
        case .peerHasNoPublicKey:
            return composed(V.Peer.messagePublicKeyRequired, V.Peer.messagePublicKeyInvalid)
        case .peerHasInvalidPublicKey:
            return composed(V.Title.publicKeyInvalid, V.Peer.messagePublicKeyInvalid)
        case .peerHasInvalidPreSharedKey:
            return composed(V.Title.preSharedKeyInvalid, V.Peer.messagePreSharedKeyInvalid)
        case .peerHasInvalidAllowedIP(let value):
            return composed(V.Title.allowedIPInvalid(value), V.Peer.messageAllowedIPsInvalid)
        case .peerHasInvalidEndpoint(let value):
            return composed(V.Title.endpointInvalid(value), V.Peer.messageEndpointInvalid)
        case .peerHasInvalidPersistentKeepAlive(let value):
            return composed(V.Title.persistentKeepliveInvalid(value), V.Peer.messagePersistentKeepaliveInvalid)
        case .peerHasUnrecognizedKey(let value):
            return composed(V.Title.unrecognizedPeerKey(value), V.Title.infoUnrecognizedPeerKey)
        case .peerHasInvalidTransferBytes(let line):
            return V.Title.invalidLine(line)
        case .peerHasInvalidLastHandshakeTime(let line):
            return V.Title.invalidLine(line)
        case .multiplePeersWithSamePublicKey:
            return V.Peer.messagePublicKeyDuplicated
        case .multipleEntriesForKey(let value):
            return V.Title.multipleEntriesForKey(value)
        }
    }
}

private func composed(_ title: String, _ info: String) -> String {
    [title, info].joined(separator: " ")
}
