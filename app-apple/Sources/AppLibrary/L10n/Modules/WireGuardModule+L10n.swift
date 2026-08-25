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
            return V.Interface.PrivateKey.required
        case .interfaceHasInvalidPrivateKey:
            return V.Interface.PrivateKey.invalid
        case .interfaceHasInvalidListenPort(let value):
            return V.Interface.ListenPort.invalid(value)
        case .interfaceHasInvalidAddress(let value):
            return V.Interface.Address.invalid(value)
        case .interfaceHasInvalidDNS(let value):
            return V.Interface.Dns.invalid(value)
        case .interfaceHasInvalidMTU(let value):
            return V.Interface.Mtu.invalid(value)
        case .interfaceHasUnrecognizedKey(let value):
            return V.Interface.unrecognizedKey(value)
        case .peerHasNoPublicKey:
            return V.Peer.PublicKey.required
        case .peerHasInvalidPublicKey:
            return V.Peer.PublicKey.invalid
        case .peerHasInvalidPreSharedKey:
            return V.Peer.PreSharedKey.invalid
        case .peerHasInvalidAllowedIP(let value):
            return V.Peer.AllowedIps.invalid(value)
        case .peerHasInvalidEndpoint(let value):
            return V.Peer.Endpoint.invalid(value)
        case .peerHasInvalidPersistentKeepAlive(let value):
            return V.Peer.PersistentKeepalive.invalid(value)
        case .peerHasUnrecognizedKey(let value):
            return V.Peer.unrecognizedKey(value)
        case .peerHasInvalidTransferBytes(let line):
            return V.invalidLine(line)
        case .peerHasInvalidLastHandshakeTime(let line):
            return V.invalidLine(line)
        case .multiplePeersWithSamePublicKey:
            return V.Peer.PublicKey.duplicated
        case .multipleEntriesForKey(let value):
            return V.multipleEntriesForKey(value)
        }
    }
}
