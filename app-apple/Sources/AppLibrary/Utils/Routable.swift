// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@MainActor
public protocol Routable {
    associatedtype Flow

    var flow: Flow? { get }
}
