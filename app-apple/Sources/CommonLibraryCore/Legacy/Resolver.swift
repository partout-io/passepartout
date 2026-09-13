// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Resolves non-final ``Module`` within a ``Profile``.
public protocol Resolver: Sendable {
    func resolvedProfile(_ profile: Profile) throws -> Profile
    func resolvedModule(_ module: Module, in profile: Profile?) throws -> Module
}
