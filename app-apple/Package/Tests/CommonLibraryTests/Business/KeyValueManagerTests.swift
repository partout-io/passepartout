// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import Testing

@MainActor
struct KeyValueManagerTests {
    @Test
    func givenKeyValue_whenSet_thenGets() {
        let sut = KeyValueManager()

        sut.set("foobar", forKey: "string")
        sut.set(true, forKey: "boolean")
        sut.set(123, forKey: "number")
        #expect(sut.object(forKey: "string") == "foobar")
        #expect(sut.object(forKey: "boolean") == true)
        #expect(sut.object(forKey: "number") == 123)
        #expect(sut.string(forKey: "string") == "foobar")
        #expect(sut.bool(forKey: "boolean") == true)
        #expect(sut.integer(forKey: "number") == 123)

        sut.removeObject(forKey: "string")
        sut.removeObject(forKey: "boolean")
        sut.removeObject(forKey: "number")
        #expect(!sut.contains("string"))
        #expect(!sut.contains("boolean"))
        #expect(!sut.contains("number"))
    }

    @Test
    func givenKeyValue_whenSetFallback_thenGetsFallback() {
        let sut = KeyValueManager(fallback: [
            "string": "foobar",
            "boolean": true,
            "number": 123
        ])
        #expect(sut.object(forKey: "string") == "foobar")
        #expect(sut.object(forKey: "boolean") == true)
        #expect(sut.object(forKey: "number") == 123)
        #expect(sut.string(forKey: "string") == "foobar")
        #expect(sut.bool(forKey: "boolean") == true)
        #expect(sut.integer(forKey: "number") == 123)
    }

    @Test
    func givenKeyValue_whenSetConfigFlags_thenIsExpected() throws {
        let flags: Set<ConfigFlag> = [.neSocketUDP, .newPaywall, .allowsRelaxedVerification]
        let sut = KeyValueManager()
        sut.preferences.configFlags = flags
        #expect(sut.preferences.configFlags == flags)

        let flagsData = try JSONEncoder().encode(flags)
        #expect(sut.preferences.configFlagsData == flagsData)
    }
}
