// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@MainActor
public final class GitHubConfigStrategy: ConfigManagerStrategy {
    private let url: URL

    private let betaURL: URL

    private let ttl: TimeInterval

    private let isBeta: @Sendable () async -> Bool

    private let fetcher: @Sendable (URL) async throws -> ABI.ConfigBundle

    private var lastUpdated: Date

    public init(
        url: URL,
        betaURL: URL,
        ttl: TimeInterval,
        isBeta: @escaping @Sendable () async -> Bool,
        fetcher: @escaping @Sendable (URL) async throws -> ABI.ConfigBundle
    ) {
        self.url = url
        self.betaURL = betaURL
        self.ttl = ttl
        self.isBeta = isBeta
        self.fetcher = fetcher
        lastUpdated = .distantPast
    }

    public func bundle() async throws -> ABI.ConfigBundle {
        let isBeta = await isBeta()
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
        let json = try await fetcher(url)
        lastUpdated = Date()
        return json
    }
}
