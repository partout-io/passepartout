// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import Partout

@MainActor
public final class GitHubConfigStrategy: ConfigManagerStrategy {
    private let url: URL

    private let betaURL: URL

    private let ttl: TimeInterval

    private let isBeta: @MainActor () -> Bool

    private var lastUpdated: Date

    public init(
        url: URL,
        betaURL: URL,
        ttl: TimeInterval,
        isBeta: @escaping () -> Bool
    ) {
        self.url = url
        self.betaURL = betaURL
        self.ttl = ttl
        self.isBeta = isBeta
        lastUpdated = .distantPast
    }

    public func bundle() async throws -> ABI.ConfigBundle {
        let isBeta = isBeta()
        pp_log_g(.App.core, .debug, "Config (GitHub): beta = \(isBeta)")
        if lastUpdated > .distantPast {
            let elapsed = -lastUpdated.timeIntervalSinceNow
            let ttl = isBeta ? ttl / 10.0 : ttl
            guard elapsed >= ttl else {
                pp_log_g(.App.core, .debug, "Config (GitHub): elapsed \(elapsed) < \(ttl)")
                throw ABI.AppError.rateLimit
            }
        }
        let targetURL = isBeta ? betaURL : url
        pp_log_g(.App.core, .info, "Config (GitHub): fetching bundle from \(targetURL)")
        var request = URLRequest(url: targetURL)
        request.cachePolicy = .reloadIgnoringCacheData
        let result = try await URLSession.shared.data(for: request)
        lastUpdated = Date()
        return try JSONDecoder().decode(ABI.ConfigBundle.self, from: result.0)
    }
}
