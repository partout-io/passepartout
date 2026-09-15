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

    func privateKey(from string: String) throws -> String

    func publicKey(from string: String) throws -> String

    func publicKey(for privateKey: String) throws -> String
}
