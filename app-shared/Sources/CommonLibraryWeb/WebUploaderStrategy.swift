// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol WebUploaderStrategy: Sendable {
    func upload(_ form: MultipartForm, to url: URL) async throws
}

public struct WebUploaderStrategyError: Error {
    public let status: Int?
    public let reason: Error?

    init(status: Int? = nil, reason: Error? = nil) {
        self.status = status
        self.reason = reason
    }
}
