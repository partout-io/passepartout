// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Default implementation of ``WireGuardKeyGenerator``.
public final class StandardWireGuardKeyGenerator: WireGuardKeyGenerator {
    public init() {
    }

    public func newPrivateKey() -> String {
        PrivateKey().base64Key
    }

    public func privateKey(from string: String) throws -> String {
        guard let key = PrivateKey(base64Key: string) else {
            throw PartoutError(.parsing)
        }
        return key.base64Key
    }

    public func publicKey(from string: String) throws -> String {
        guard let key = PublicKey(base64Key: string) else {
            throw PartoutError(.parsing)
        }
        return key.base64Key
    }

    public func publicKey(for privateKey: String) throws -> String {
        guard let key = PrivateKey(base64Key: privateKey) else {
            throw PartoutError(.parsing)
        }
        return key.publicKey.base64Key
    }
}
