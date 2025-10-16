// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonProviders
import Testing

struct ProviderScriptingEngineTests {
    @Test
    func givenEngine_whenUseAPI_thenWorks() async throws {
        let api = DefaultProviderScriptingAPI(.global, timeout: 3.0)
        let sut = api.newScriptingEngine(.global)

        let version = try await sut.execute("JSON.stringify(api.version())", after: nil, returning: String.self)
        #expect(version == "20250718")

        let base64 = try await sut.execute("JSON.stringify(api.jsonToBase64({\"foo\":\"bar\"}))", after: nil, returning: String.self)
        #expect(base64 == "eyJmb28iOiJiYXIifQ==")
    }
}
