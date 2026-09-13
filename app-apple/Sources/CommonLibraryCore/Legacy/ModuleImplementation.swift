// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Marker for ``Module`` internal implementations. Must be actor-safe.
/// - Seealso: Implementations are managed by a ``ModuleRegistry``.
public protocol ModuleImplementation: AnyObject, Sendable {
    /// The unique identifier of the associated handler. It helps a ``ModuleRegistry`` find out about the implementation of a known module.
    var moduleType: ModuleType { get }
}
