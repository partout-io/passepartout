// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
import SwiftUI

public struct ChangelogView: View {
    @Environment(VersionObservable.self)
    private var versionObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @State
    private var entries: [ABI.ChangelogEntry] = []

    @State
    private var isLoading = true

    public init() {
    }

    public var body: some View {
        Form {
            ForEach(entries, id: \.id) { entry in
                if let url = entry.issueURL(cfg: appConfiguration) {
                    Link(entry.comment, destination: url)
                } else {
                    Text(entry.comment)
                }
            }
            .themeSection(header: versionString)
        }
        .themeForm()
        .themeProgress(
            if: isLoading,
            isEmpty: entries.isEmpty,
            emptyMessage: Strings.Global.Nouns.noContent
        )
        .task {
            await loadChangelog()
        }
    }
}

private extension ChangelogView {
    var versionString: String {
        appConfiguration.bundle.versionString
    }

    var versionNumber: String {
        appConfiguration.bundle.versionNumber
    }

    func loadChangelog() async {
        do {
            entries = try await versionObservable.fetchChangelog(of: versionNumber)
        } catch {
            pspLog(.core, .error, "CHANGELOG: Unable to load: \(error)")
        }
        isLoading = false
    }
}

#endif
