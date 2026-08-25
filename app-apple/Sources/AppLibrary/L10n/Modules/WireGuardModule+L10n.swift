// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension WireGuardParseError: @retroactive LocalizedError {
    public var errorDescription: String? {
        let V = Strings.Errors.Wireguard.self
        switch self {
        case .invalidLine(let line):
            return V.invalidLine(line)
        case .noInterface:
            return V.noInterface
        case .multipleInterfaces:
            return V.multipleInterfaces
        case .interfaceHasNoPrivateKey:
            return V.Interface.privateKeyRequired
        case .interfaceHasInvalidPrivateKey:
            return V.Interface.privateKeyInvalid
        case .interfaceHasInvalidListenPort(let value):
            return V.Interface.listenPortInvalid(value)
        case .interfaceHasInvalidAddress(let value):
            return V.Interface.addressInvalid(value)
        case .interfaceHasInvalidDNS(let value):
            return V.Interface.dnsInvalid(value)
        case .interfaceHasInvalidMTU(let value):
            return V.Interface.mtuInvalid(value)
        case .interfaceHasUnrecognizedKey(let value):
            return V.Interface.unrecognizedKey(value)
        case .peerHasNoPublicKey:
            return V.Peer.publicKeyRequired
        case .peerHasInvalidPublicKey:
            return V.Peer.publicKeyInvalid
        case .peerHasInvalidPreSharedKey:
            return V.Peer.preSharedKeyInvalid
        case .peerHasInvalidAllowedIP(let value):
            return V.Peer.allowedIPsInvalid(value)
        case .peerHasInvalidEndpoint(let value):
            return V.Peer.endpointInvalid(value)
        case .peerHasInvalidPersistentKeepAlive(let value):
            return V.Peer.persistentKeepaliveInvalid(value)
        case .peerHasUnrecognizedKey(let value):
            return V.Peer.unrecognizedKey(value)
        case .peerHasInvalidTransferBytes(let line):
            return V.invalidLine(line)
        case .peerHasInvalidLastHandshakeTime(let line):
            return V.invalidLine(line)
        case .multiplePeersWithSamePublicKey:
            return V.Peer.publicKeyDuplicated
        case .multipleEntriesForKey(let value):
            return V.multipleEntriesForKey(value)
        }
    }
}
