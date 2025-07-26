// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@MainActor
public protocol ProfileProcessor: Sendable {
    func isIncluded(_ profile: Profile) -> Bool

    func preview(from profile: Profile) -> ProfilePreview

    func requiredFeatures(_ profile: Profile) -> Set<AppFeature>?

    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder
}

@MainActor
public protocol AppTunnelProcessor: Sendable {
    func title(for profile: Profile) -> String

    func willInstall(_ profile: Profile) async throws -> Profile
}

public protocol PacketTunnelProcessor: Sendable {
    nonisolated func willProcess(_ profile: Profile) throws -> Profile
}
