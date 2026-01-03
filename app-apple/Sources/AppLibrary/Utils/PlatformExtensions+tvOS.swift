// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

#if os(tvOS)

extension View {
    public func cursor(_ cursor: CursorType) -> some View {
        self
    }
}

#endif
