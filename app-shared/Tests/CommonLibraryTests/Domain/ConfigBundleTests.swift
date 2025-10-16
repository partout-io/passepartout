// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Testing

struct ConfigBundleTests {
    @Test(arguments: [
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 10, minBuild: nil, data: nil)], false),
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 100, minBuild: nil, data: nil)], true),
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 200, minBuild: nil, data: nil)], false)
    ])
    func givenBundle_whenRate100_thenIsActive(map: [ConfigFlag: ConfigBundle.Config], isActive: Bool) {
        let sut = ConfigBundle(map: map)
        let activeFlags: Set<ConfigFlag> = isActive ? [.appNotWorking] : []
        #expect(sut.activeFlags(withBuild: 1) == activeFlags)
    }

    @Test(arguments: [
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 100, minBuild: nil, data: nil)], true),
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 100, minBuild: 500, data: nil)], true),
        ([ConfigFlag.appNotWorking: ConfigBundle.Config(rate: 100, minBuild: 1000, data: nil)], false)
    ])
    func givenBundle_whenMinBuild_thenIsActive(map: [ConfigFlag: ConfigBundle.Config], isActive: Bool) {
        let sut = ConfigBundle(map: map)
        let activeFlags: Set<ConfigFlag> = isActive ? [.appNotWorking] : []
        #expect(sut.activeFlags(withBuild: 750) == activeFlags)
    }
}
