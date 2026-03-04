// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@MainActor
public protocol ProfileProcessor: AnyObject, Sendable {
    func isIncluded(_ profile: Profile) -> Bool
    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>?
    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder
}

public protocol AppTunnelProcessor: AnyObject, Sendable {
    nonisolated func title(for profile: Profile) -> String
    nonisolated func willInstall(_ profile: Profile) async throws -> Profile
}

public protocol PacketTunnelProcessor: AnyObject, Sendable {
    nonisolated func willProcess(_ profile: Profile) throws -> Profile
}
