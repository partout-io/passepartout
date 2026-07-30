// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct ProfileAttributesTests {
    @Test
    func givenUserInfo_whenInit_thenReturnsAttributes() throws {
        let fingerprint = UniqueID()
        let lastUpdate = Date()
        let isAvailableForTV = true
        let userInfo = try JSON([
            "fingerprint": fingerprint.uuidString,
            "lastUpdate": lastUpdate.timeIntervalSinceReferenceDate,
            "isAvailableForTV": isAvailableForTV
        ])

        let sut = ProfileAttributes(userInfo: userInfo)
        #expect(sut.userInfo == userInfo)
        #expect(sut.fingerprint == fingerprint)
        #expect(sut.lastUpdate == lastUpdate)
        #expect(sut.isAvailableForTV == isAvailableForTV)
    }

    @Test
    func givenUserInfo_whenSet_thenReturnsAttributes() throws {
        let fingerprint = UniqueID()
        let lastUpdate = Date()
        let isAvailableForTV = true
        let userInfo = try JSON([
            "fingerprint": fingerprint.uuidString,
            "lastUpdate": lastUpdate.timeIntervalSinceReferenceDate,
            "isAvailableForTV": isAvailableForTV
        ])

        var sut = ProfileAttributes(userInfo: nil)
        sut.fingerprint = fingerprint
        sut.lastUpdate = lastUpdate
        sut.isAvailableForTV = isAvailableForTV
        #expect(sut.userInfo == userInfo)
        #expect(sut.fingerprint == fingerprint)
        #expect(sut.lastUpdate == lastUpdate)
        #expect(sut.isAvailableForTV == isAvailableForTV)
    }

    @Test
    func givenUserInfo_whenInit_thenReturnsModulePreferences() throws {
        let moduleId1 = UniqueID()
        let moduleId2 = UniqueID()
        let excludedEndpoints: [String] = [
            "1.1.1.1:UDP6:1000",
            "2.2.2.2:TCP4:2000",
            "3.3.3.3:TCP:3000"
        ]
        let moduleUserInfo = [
            "excludedEndpoints": excludedEndpoints
        ]
        let userInfo = try JSON([
            "preferences": [
                moduleId1.uuidString: moduleUserInfo,
                moduleId2.uuidString: moduleUserInfo
            ]
        ])

        let sut = ProfileAttributes(userInfo: userInfo)
        #expect(sut.userInfo == userInfo)
        for moduleId in [moduleId1, moduleId2] {
            let module = sut.preferences(inModule: moduleId)
            let reversedUserInfo = try JSON(moduleUserInfo)
            #expect(module.userInfo == reversedUserInfo)
            #expect(module.rawExcludedEndpoints == excludedEndpoints)
        }
    }

    @Test
    func givenUserInfo_whenSet_thenReturnsModulePreferences() throws {
        let moduleId1 = UniqueID()
        let moduleId2 = UniqueID()
        let excludedEndpoints: [String] = [
            "1.1.1.1:UDP6:1000",
            "2.2.2.2:TCP4:2000",
            "3.3.3.3:TCP:3000"
        ]
        let moduleUserInfo = [
            "excludedEndpoints": excludedEndpoints
        ]
        let userInfo = try JSON([
            "preferences": [
                moduleId1.uuidString: moduleUserInfo,
                moduleId2.uuidString: moduleUserInfo
            ]
        ])

        var sut = ProfileAttributes(userInfo: nil)
        for moduleId in [moduleId1, moduleId2] {
            var module = sut.preferences(inModule: moduleId1)
            module.rawExcludedEndpoints = excludedEndpoints
            let reversedUserInfo = try JSON(moduleUserInfo)
            #expect(module.userInfo == reversedUserInfo)
            sut.setPreferences(module, inModule: moduleId)
        }
        #expect(sut.userInfo == userInfo)
    }
}
