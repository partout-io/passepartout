// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol VersionCheckerStrategy: Sendable {
    func latestVersion(since: Date) async throws -> ABI.SemanticVersion
}
