// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

public struct VersionUpdateLink: View {
    @Environment(VersionObservable.self)
    private var versionChecker

    private let withIcon: Bool?

    public init(withIcon: Bool? = nil) {
        self.withIcon = withIcon
    }

    public var body: some View {
        versionChecker.latestRelease
            .map { latest in
                ExternalLink(
                    Strings.Views.Settings.Links.update(latest.version),
                    url: latest.url,
                    withIcon: withIcon
                )
            }
    }
}
