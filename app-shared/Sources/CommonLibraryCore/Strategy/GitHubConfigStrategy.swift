// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

@MainActor
public final class GitHubConfigStrategy: ConfigManagerStrategy {
    private let logger: AppLogger

    private let url: URL

    private let betaURL: URL

    private let ttl: TimeInterval

    private let isBeta: @Sendable () async -> Bool

    private let fetcher: @Sendable (URL) async throws -> Data

    private var lastUpdated: Date

    public init(
        _ logger: AppLogger,
        url: URL,
        betaURL: URL,
        ttl: TimeInterval,
        isBeta: @escaping @Sendable () async -> Bool,
        fetcher: @escaping @Sendable (URL) async throws -> Data
    ) {
        self.logger = logger
        self.url = url
        self.betaURL = betaURL
        self.ttl = ttl
        self.isBeta = isBeta
        self.fetcher = fetcher
        lastUpdated = .distantPast
    }

    public func bundle() async throws -> ABI.ConfigBundle {
        let isBeta = await isBeta()
        logger.log(.core, .debug, "Config (GitHub): beta = \(isBeta)")
        if lastUpdated > .distantPast {
            let elapsed = -lastUpdated.timeIntervalSinceNow
            let ttl = isBeta ? ttl / 10.0 : ttl
            guard elapsed >= ttl else {
                logger.log(.core, .debug, "Config (GitHub): elapsed \(elapsed) < \(ttl)")
                throw ABI.AppError.rateLimit
            }
        }
        let targetURL = isBeta ? betaURL : url
        logger.log(.core, .info, "Config (GitHub): fetching bundle from \(targetURL)")
        let data = try await fetcher(targetURL)
        let json = try JSONDecoder().decode(ABI.ConfigBundle.self, from: data)
        lastUpdated = Date()
        return json
    }
}
