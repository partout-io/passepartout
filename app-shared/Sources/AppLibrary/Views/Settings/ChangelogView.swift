// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import CommonLibrary
import CommonUtils
import SwiftUI
import WebKit

public struct ChangelogView: View {

    @State
    private var entries: [ChangelogEntry] = []

    @State
    private var isLoading = true

    public init() {
    }

    public var body: some View {
        Form {
            ForEach(entries, id: \.id) { entry in
                if let url = entry.issueURL {
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
        BundleConfiguration.mainVersionString
    }

    var versionNumber: String {
        BundleConfiguration.mainVersionNumber
    }

    func loadChangelog() async {
        do {
            pp_log_g(.App.core, .info, "CHANGELOG: Load for version \(versionNumber)")
            let url = Constants.shared.github.urlForChangelog(ofVersion: versionNumber)
            pp_log_g(.App.core, .info, "CHANGELOG: Fetching \(url)")
            let result = try await URLSession.shared.data(from: url)
            guard let text = String(data: result.0, encoding: .utf8) else {
                throw AppError.notFound
            }
            entries = text
                .split(separator: "\n")
                .enumerated()
                .compactMap {
                    ChangelogEntry($0.offset, line: String($0.element))
                }
        } catch {
            pp_log_g(.App.core, .error, "CHANGELOG: Unable to load: \(error)")
        }
        isLoading = false
    }
}

#endif
