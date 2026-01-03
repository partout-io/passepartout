// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

@MainActor
public protocol SizeClassProviding {
    var hsClass: UserInterfaceSizeClass? { get }

    var vsClass: UserInterfaceSizeClass? { get }
}

extension SizeClassProviding {
    public var isBigDevice: Bool {
        hsClass == .regular && vsClass == .regular
    }
}
