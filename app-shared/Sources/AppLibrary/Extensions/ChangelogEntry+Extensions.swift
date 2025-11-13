// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension ChangelogEntry {
    public var issueURL: URL? {
        issue.map {
            Constants.shared.github.urlForIssue($0)
        }
    }
}
