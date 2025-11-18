// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public protocol Routable {
    associatedtype Flow

    var flow: Flow? { get }
}
