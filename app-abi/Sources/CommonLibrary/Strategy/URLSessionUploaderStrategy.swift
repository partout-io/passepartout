// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

public final class URLSessionUploaderStrategy: WebUploaderStrategy {
    private let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func upload(_ form: MultipartForm, to url: URL) async throws {
        var request = form.toURLRequest(url: url)
        request.timeoutInterval = timeout
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.webUploader(nil, nil)
            }
            let statusCode = httpResponse.statusCode
            guard statusCode == 200 else {
                switch statusCode {
                case 400:
                    assertionFailure("WebUploader: invalid form, bug in MultipartForm")
                default:
                    break
                }
                throw AppError.webUploader(statusCode, nil)
            }
        } catch {
            throw AppError.webUploader(nil, error)
        }
    }
}
