// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ABI.ChangelogEntry {
    public func issueURL(cfg: ABI.AppConfiguration) -> URL? {
        issue.map {
            cfg.constants.github.urlForIssue($0)
        }
    }
}
