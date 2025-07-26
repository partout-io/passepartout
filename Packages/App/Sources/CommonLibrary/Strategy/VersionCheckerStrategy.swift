// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol VersionCheckerStrategy {
    func latestVersion(since: Date) async throws -> SemanticVersion
}
