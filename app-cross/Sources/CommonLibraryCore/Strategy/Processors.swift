// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol ProfileProcessor: AnyObject, Sendable {
    func isIncluded(_ profile: Profile) -> Bool
    @BusinessActor
    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>?
}

public protocol AppTunnelProcessor: AnyObject, Sendable {
    nonisolated func title(for profile: Profile) -> String
    nonisolated func willInstall(_ profile: Profile) async throws -> Profile
}

public protocol PacketTunnelProcessor: AnyObject, Sendable {
    nonisolated func willProcess(_ profile: Profile) throws -> Profile
}
