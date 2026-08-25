// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

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
            return composed(V.Interface.privateKeyRequired, V.Interface.privateKeyInvalid)
        case .interfaceHasInvalidPrivateKey:
            return composed(V.Title.privateKeyInvalid, V.Interface.privateKeyInvalid)
        case .interfaceHasInvalidListenPort(let value):
            return composed(V.Title.listenPortInvalid(value), V.Interface.listenPortInvalid)
        case .interfaceHasInvalidAddress(let value):
            return composed(V.Title.addressInvalid(value), V.Interface.addressInvalid)
        case .interfaceHasInvalidDNS(let value):
            return composed(V.Title.dnsInvalid(value), V.Interface.dnsInvalid)
        case .interfaceHasInvalidMTU(let value):
            return composed(V.Title.mtuInvalid(value), V.Interface.mtuInvalid)
        case .interfaceHasUnrecognizedKey(let value):
            return composed(V.Title.unrecognizedInterfaceKey(value), V.Title.infoUnrecognizedInterfaceKey)
        case .peerHasNoPublicKey:
            return composed(V.Peer.publicKeyRequired, V.Peer.publicKeyInvalid)
        case .peerHasInvalidPublicKey:
            return composed(V.Title.publicKeyInvalid, V.Peer.publicKeyInvalid)
        case .peerHasInvalidPreSharedKey:
            return composed(V.Title.preSharedKeyInvalid, V.Peer.preSharedKeyInvalid)
        case .peerHasInvalidAllowedIP(let value):
            return composed(V.Title.allowedIPInvalid(value), V.Peer.allowedIPsInvalid)
        case .peerHasInvalidEndpoint(let value):
            return composed(V.Title.endpointInvalid(value), V.Peer.endpointInvalid)
        case .peerHasInvalidPersistentKeepAlive(let value):
            return composed(V.Title.persistentKeepliveInvalid(value), V.Peer.persistentKeepaliveInvalid)
        case .peerHasUnrecognizedKey(let value):
            return composed(V.Title.unrecognizedPeerKey(value), V.Title.infoUnrecognizedPeerKey)
        case .peerHasInvalidTransferBytes(let line):
            return V.Title.invalidLine(line)
        case .peerHasInvalidLastHandshakeTime(let line):
            return V.Title.invalidLine(line)
        case .multiplePeersWithSamePublicKey:
            return V.Peer.publicKeyDuplicated
        case .multipleEntriesForKey(let value):
            return V.Title.multipleEntriesForKey(value)
        }
    }
}

private func composed(_ title: String, _ info: String) -> String {
    [title, info].joined(separator: " ")
}
