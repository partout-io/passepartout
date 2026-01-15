// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Partout
import Testing

@MainActor
struct KeyValueStoreTests {
    @Test
    func givenKeyValue_whenSet_thenGets() {
        let sut = InMemoryStore()

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
    func givenKeyValue_whenSetConfigFlags_thenIsExpected() throws {
        let flags: Set<ABI.ConfigFlag> = [.neSocketUDP, .allowsRelaxedVerification]
        let sut = InMemoryStore()
        sut.preferences.configFlags = flags
        #expect(sut.preferences.configFlags == flags)

        let flagsData = try JSONEncoder().encode(flags)
        #expect(sut.preferences.configFlagsData == flagsData)
    }
}
