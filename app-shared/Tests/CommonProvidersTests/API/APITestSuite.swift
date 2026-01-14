// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonProviders
import Partout

protocol APITestSuite {
}

extension APITestSuite {
    func newAPIMapper(_ requestHijacker: (@Sendable (String, String) -> (Int, Data))? = nil) throws -> APIMapper {
        guard let baseURL = API.url() else {
            fatalError("Could not find resource path")
        }
        return DefaultAPIMapper(
            .global,
            baseURL: baseURL,
            timeout: 3.0,
            api: DefaultProviderScriptingAPI(
                .global,
                timeout: 3.0,
                requestHijacker: requestHijacker
            )
        )
    }

    func setUpLogging() {
        var logger = PartoutLogger.Builder()
#if canImport(OSLog)
        logger.setDestination(OSLogDestination(.providers), for: [.providers])
#endif
        PartoutLogger.register(logger.build())
    }

    func measureFetchProvider() async throws {
        let sut = try newAPIMapper()
        let begin = Date()
        for _ in 0..<1000 {
            let module = try ProviderModule(emptyWithProviderId: .hideme)
            _ = try await sut.infrastructure(for: module, cache: nil)
        }
        print("Elapsed: \(-begin.timeIntervalSinceNow)")
    }
}
