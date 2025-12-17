// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol VersionCheckerStrategy: Sendable {
    func latestVersion(since: Date) async throws -> ABI.SemanticVersion
}
