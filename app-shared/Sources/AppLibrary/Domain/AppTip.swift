// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public struct AppTip: Identifiable, Sendable {
    public let id: String

    public let titleString: String

    public let messageString: String

    public init(id: String, titleString: String, messageString: String) {
        self.id = id
        self.titleString = titleString
        self.messageString = messageString
    }
}
