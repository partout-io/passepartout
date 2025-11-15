// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import XCTest

final class ProfileAttributesTests: XCTestCase {
    func test_givenUserInfo_whenInit_thenReturnsAttributes() throws {
        let fingerprint = UUID()
        let lastUpdate = Date()
        let isAvailableForTV = true
        let userInfo = try JSON([
            "fingerprint": fingerprint.uuidString,
            "lastUpdate": lastUpdate.timeIntervalSinceReferenceDate,
            "isAvailableForTV": isAvailableForTV
        ])

        let sut = ProfileAttributes(userInfo: userInfo)
        XCTAssertEqual(sut.userInfo, userInfo)
        XCTAssertEqual(sut.fingerprint, fingerprint)
        XCTAssertEqual(sut.lastUpdate, lastUpdate)
        XCTAssertEqual(sut.isAvailableForTV, isAvailableForTV)
    }

    func test_givenUserInfo_whenSet_thenReturnsAttributes() throws {
        let fingerprint = UUID()
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
        XCTAssertEqual(sut.userInfo, userInfo)
        XCTAssertEqual(sut.fingerprint, fingerprint)
        XCTAssertEqual(sut.lastUpdate, lastUpdate)
        XCTAssertEqual(sut.isAvailableForTV, isAvailableForTV)
    }

    func test_givenUserInfo_whenInit_thenReturnsModulePreferences() throws {
        let moduleId1 = UUID()
        let moduleId2 = UUID()
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
        XCTAssertEqual(sut.userInfo, userInfo)
        for moduleId in [moduleId1, moduleId2] {
            let module = sut.preferences(inModule: moduleId)
            XCTAssertEqual(module.userInfo, try JSON(moduleUserInfo))
            XCTAssertEqual(module.rawExcludedEndpoints, excludedEndpoints)
        }
    }

    func test_givenUserInfo_whenSet_thenReturnsModulePreferences() throws {
        let moduleId1 = UUID()
        let moduleId2 = UUID()
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
            XCTAssertEqual(module.userInfo, try JSON(moduleUserInfo))
            sut.setPreferences(module, inModule: moduleId)
        }
        XCTAssertEqual(sut.userInfo, userInfo)
    }
}
