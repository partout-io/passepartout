// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Testing

struct ConfigBundleTests {
    @Test(arguments: [
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 10, minBuild: nil, data: nil)], false),
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 100, minBuild: nil, data: nil)], true),
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 200, minBuild: nil, data: nil)], false)
    ])
    func givenBundle_whenRate100_thenIsActive(map: [ABI.ConfigFlag: ABI.ConfigBundle.Config], isActive: Bool) {
        let sut = ABI.ConfigBundle(map: map)
        let activeFlags: Set<ABI.ConfigFlag> = isActive ? [.appNotWorking] : []
        #expect(sut.activeFlags(withBuild: 1) == activeFlags)
    }

    @Test(arguments: [
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 100, minBuild: nil, data: nil)], true),
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 100, minBuild: 500, data: nil)], true),
        ([ABI.ConfigFlag.appNotWorking: ABI.ConfigBundle.Config(rate: 100, minBuild: 1000, data: nil)], false)
    ])
    func givenBundle_whenMinBuild_thenIsActive(map: [ABI.ConfigFlag: ABI.ConfigBundle.Config], isActive: Bool) {
        let sut = ABI.ConfigBundle(map: map)
        let activeFlags: Set<ABI.ConfigFlag> = isActive ? [.appNotWorking] : []
        #expect(sut.activeFlags(withBuild: 750) == activeFlags)
    }
}
