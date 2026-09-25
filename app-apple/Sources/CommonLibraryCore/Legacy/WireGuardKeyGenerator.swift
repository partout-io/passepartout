// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Generates WireGuard keys.
///
/// Generates both private and public keys for use with the WireGuard protocol, required to build a ``WireGuard/Configuration``. The exchanged
/// encoding must be Base64.
///
public protocol WireGuardKeyGenerator: Sendable {
    func newPrivateKey() -> String
    func publicKey(for privateKey: String) throws -> String
}

public final class FakeWireGuardKeyGenerator: WireGuardKeyGenerator {
    public init() {}

    public func newPrivateKey() -> String {
        "foobar"
    }

    public func publicKey(for privateKey: String) throws -> String {
        "foobar"
    }
}
