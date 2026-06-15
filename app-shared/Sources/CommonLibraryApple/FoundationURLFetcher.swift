// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public final class FoundationURLFetcher: URLFetcher {
    private let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    public func data(for url: URL, cached: Bool) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = cached ? .useProtocolCachePolicy : .reloadIgnoringCacheData
        request.timeoutInterval = timeout
        do {
            return try await URLSession.shared.data(for: request).0
        } catch {
            throw ABI.AppError.urlRequestFailed(reason: error)
        }
    }
}
