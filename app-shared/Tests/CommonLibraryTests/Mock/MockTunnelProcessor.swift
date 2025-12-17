// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

final class MockTunnelProcessor: AppTunnelProcessor, @unchecked Sendable {
    var titleCount = 0

    var willInstallCount = 0

    func title(for profile: Profile) -> String {
        titleCount += 1
        return ""
    }

    func willInstall(_ profile: Profile) throws -> Profile {
        willInstallCount += 1
        return profile
    }
}
