// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Foundation

extension ABI.ChangelogEntry {
    public var issueURL: URL? {
        issue.map {
            Resources.constants.github.urlForIssue($0)
        }
    }
}
