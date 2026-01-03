// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol WebUploaderStrategy: Sendable {
    func upload(_ form: MultipartForm, to url: URL) async throws
}

public struct WebUploaderStrategyError: Error {
    public let status: Int?
    public let reason: Error?

    public init(status: Int? = nil, reason: Error? = nil) {
        self.status = status
        self.reason = reason
    }
}
