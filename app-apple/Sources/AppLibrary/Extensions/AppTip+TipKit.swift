// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import TipKit

@available(iOS 17, macOS 14, *)
extension AppTip: Tip {
    public var title: Text {
        Text(titleString)
    }

    public var message: Text? {
        Text(messageString)
    }
}
