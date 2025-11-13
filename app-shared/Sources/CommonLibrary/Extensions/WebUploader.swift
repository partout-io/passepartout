// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

@MainActor
public final class WebUploader: ObservableObject, Sendable {
    private let strategy: WebUploaderStrategy

    private let logger: WebLogger

    public init(strategy: WebUploaderStrategy, logger: WebLogger) {
        self.strategy = strategy
        self.logger = logger
    }

    public func send(_ content: String, filename: String, to url: URL, passcode: String) async throws {
        logger.info("WebUploader: sending to \(url) with passcode \(passcode)")
        var formBuilder = MultipartForm.Builder()
        formBuilder.fields["passcode"] = MultipartForm.Field(passcode)
        formBuilder.fields["file"] = MultipartForm.Field(content, filename: filename)
        let form = formBuilder.build()
        do {
            try await strategy.upload(form, to: url)
        } catch let error as WebUploaderStrategyError {
            throw AppError.webUploader(error.status, error.reason)
        }
    }
}
