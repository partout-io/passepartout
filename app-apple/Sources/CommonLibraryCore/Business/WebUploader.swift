// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class WebUploader: Sendable {
    private let strategy: WebUploaderStrategy

    public init(strategy: WebUploaderStrategy) {
        self.strategy = strategy
    }

    public func send(_ content: String, filename: String, to url: URL, passcode: String) async throws {
        pspLog(.web, .info, "WebUploader: sending to \(url) with passcode \(passcode)")
        var formBuilder = MultipartForm.Builder()
        formBuilder.fields["passcode"] = MultipartForm.Field(passcode)
        formBuilder.fields["file"] = MultipartForm.Field(content, filename: filename)
        let form = formBuilder.build()
        do {
            try await strategy.upload(form, to: url)
        } catch let error as WebUploaderStrategyError {
            throw ABI.AppError.webUploader(error.status, error.reason)
        }
    }
}
