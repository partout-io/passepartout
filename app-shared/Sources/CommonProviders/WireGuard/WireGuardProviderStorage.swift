// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_DYNLIB
import CommonProvidersCore
#endif
import Foundation
import Partout

public struct WireGuardProviderStorage: ProviderOptions {

    // device id -> session
    public var sessions: [String: Session]?

    public init() {
    }
}

extension WireGuardProviderStorage {
    public struct Session: Hashable, Codable, Sendable {
        public let privateKey: String

        public let publicKey: String

        public private(set) var peer: Peer?

        init(privateKey: String, publicKey: String) {
            self.privateKey = privateKey
            self.publicKey = publicKey
        }

        public init(keyGenerator: WireGuardKeyGenerator) throws {
            privateKey = keyGenerator.newPrivateKey()
            publicKey = try keyGenerator.publicKey(for: privateKey)
            peer = nil
        }

        public func renewed(with keyGenerator: WireGuardKeyGenerator) throws -> Self {
            var newSession = try Self(keyGenerator: keyGenerator)
            newSession.peer = peer
            return newSession
        }

        func with(peer: Peer?) -> Self {
            var newSession = self
            newSession.peer = peer
            return newSession
        }
    }

    public struct Peer: Identifiable, Hashable, Codable, Sendable {
        public let id: String

        public let creationDate: Date

        public let addresses: [String]

        public init(id: String, creationDate: Date, addresses: [String]) {
            self.id = id
            self.creationDate = creationDate
            self.addresses = addresses
        }
    }
}
