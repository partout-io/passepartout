// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class URLSessionUploaderStrategy: WebUploaderStrategy {
    private let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func upload(_ form: MultipartForm, to url: URL) async throws {
        var request = form.toURLRequest(url: url)
        request.timeoutInterval = timeout
        let result: (Data, URLResponse)
        do {
            result = try await URLSession.shared.data(for: request)
        } catch {
            throw WebUploaderStrategyError(reason: error)
        }
        guard let httpResponse = result.1 as? HTTPURLResponse else {
            throw WebUploaderStrategyError()
        }
        let statusCode = httpResponse.statusCode
        guard statusCode == 200 else {
            switch statusCode {
            case 400:
                assertionFailure("WebUploader: invalid form, bug in MultipartForm")
            default:
                break
            }
            throw WebUploaderStrategyError(status: statusCode)
        }
    }
}
