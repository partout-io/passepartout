// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonProviders
import Testing

struct ProviderScriptingAPITests {
    @Test
    func givenAPI_whenGetVersion_thenIsExpected() {
        let sut = DefaultProviderScriptingAPI(.global, timeout: 3.0)
        #expect(sut.version == "20250718")
    }

    @Test
    func givenAPI_whenProviderGetResult_thenIsMapped() {
        let sut: ProviderScriptingAPI
        do {
            let url = try #require(Bundle.module.url(forResource: "Resources/mapped", withExtension: "txt"))
            let data = try Data(contentsOf: url)
            sut = DefaultProviderScriptingAPI(.global, timeout: 3.0) {
                #expect($0 == "GET")
                #expect($1 == "doesntmatter")
                return (200, data)
            }
        } catch {
            fatalError("Unable to return bundle resource: \(error)")
        }
        let map = sut.getText(urlString: "doesntmatter", headers: nil)
        #expect(map["response"] as? String == "mapped content\n")
    }

    @Test(arguments: [
        (1752562800, "Tue, 15 Jul 2025 07:00:00 GMT"),
        (1698907632, "Thu, 02 Nov 2023 06:47:12 GMT")
    ])
    func givenTimestamp_whenGetRFC1123_thenIsExpected(timestamp: Timestamp, rfc: String) {
        #expect(timestamp.toRFC1123() == rfc)
        #expect(rfc.fromRFC1123() == timestamp)
    }

    @Test
    func givenScriptResult_whenHasCache_thenReturnsProviderCache() throws {
        let date = Timestamp.now()
        let tag = "12345"
        let sut = ProviderScriptResult("", status: nil, lastModified: date, tag: tag)

        let object = try #require(sut.serialized()["cache"])
        let data = try JSONSerialization.data(withJSONObject: object)
        let cache = try JSONDecoder().decode(ProviderCache.self, from: data)

        #expect(cache.lastUpdate == date)
        #expect(cache.tag == tag)
    }
}
