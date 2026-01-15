// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import MiniFoundation

extension ABI {
    public struct VersionRelease: Hashable, Sendable {
        public let version: ABI.SemanticVersion

        public let url: URL
    }
}
