// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import SwiftUI

struct DiagnosticsView: View {
    @Environment(Theme.self)
    private var theme

    @Environment(AppFormatter.self)
    private var appFormatter

    @EnvironmentObject
    private var apiManager: APIManager

    @Environment(IAPObservable.self)
    private var iapObservable

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Environment(ConfigObservable.self)
    private var configObservable

    let profileObservable: ProfileObservable

    let tunnel: TunnelObservable

    var availableTunnelLogs: (() async -> [ABI.LogEntry])?

    @State
    private var logsPrivateData = false

    @State
    private var tunnelLogs: [ABI.LogEntry] = []

    @State
    var isPresentingUnableToEmail = false

    var body: some View {
        Form {
            if iapObservable.isBeta {
                BetaSection()
            }
            liveLogSection
            profilesSection
            if appConfiguration.distributionTarget.supportsAppGroups {
                tunnelLogsSection
            }
            if canReportIssue {
                reportIssueSection
            }
            debugSection
        }
        .task {
            tunnelLogs = await computedTunnelLogs()
        }
        .themeForm()
        .alert(Strings.Views.Diagnostics.ReportIssue.title, isPresented: $isPresentingUnableToEmail) {
            Button(Strings.Global.Nouns.ok, role: .cancel) {
                isPresentingUnableToEmail = false
            }
        } message: {
            Text(Strings.Views.Diagnostics.Alerts.ReportIssue.email)
        }
    }
}

private extension DiagnosticsView {
    var liveLogSection: some View {
        Group {
            navLink(
                Strings.Views.Diagnostics.Rows.app,
                to: .appLog(title: Strings.Views.Diagnostics.Rows.app)
            )
            navLink(
                Strings.Views.Diagnostics.Rows.tunnel,
                to: .tunnelLog(title: Strings.Views.Diagnostics.Rows.tunnel, url: nil)
            )
            LogsPrivateDataToggle()
        }
        .themeSection(header: Strings.Views.Diagnostics.Sections.live)
    }

    var profilesSection: some View {
        activeProfiles
            .nilIfEmpty
            .map {
                ForEach($0) { profile in
                    NavigationLink(profile.name, value: DiagnosticsRoute.profile(profile: profile))
                }
                .themeSection(header: Strings.Views.Diagnostics.Sections.activeProfiles)
            }
    }

    var tunnelLogsSection: some View {
        Group {
            Button(Strings.Views.Diagnostics.Rows.removeTunnelLogs) {
                withAnimation(theme.animation(for: .diagnostics), removeTunnelLogs)
            }
            .disabled(tunnelLogs.isEmpty)

            ForEach(tunnelLogs, id: \.date, content: logView)
                .onDelete(perform: removeTunnelLogs)
        }
        .themeSection(header: Strings.Views.Diagnostics.Sections.tunnel)
        .themeAnimation(on: tunnelLogs, category: .diagnostics)
    }

    var reportIssueSection: some View {
        Section {
            ReportIssueButton(
                title: Strings.Views.Diagnostics.ReportIssue.title,
                tunnel: tunnel,
                apiManager: apiManager,
                purchasedProducts: iapObservable.purchasedProducts,
                isUnableToEmail: $isPresentingUnableToEmail
            )
        }
    }

    func logView(for item: ABI.LogEntry) -> some View {
        ThemeRemovableItemRow(isEditing: true) {
            let dateString = appFormatter.string(from: item.date)
            navLink(dateString, to: .tunnelLog(title: dateString, url: item.url))
        } removeAction: {
            removeTunnelLog(at: item.url)
        }
    }

    func navLink(_ title: String, to value: DiagnosticsRoute) -> some View {
        NavigationLink(title, value: value)
    }

    var debugSection: some View {
        // FIXME: #1594, Drop after migration
        Text("Using new Observables")
    }
}

private extension DiagnosticsView {
    var activeProfiles: [Profile] {
        tunnel.activeProfiles
            .values
            .compactMap {
                profileObservable.profile(withId: $0.id)?.native
            }
            .sorted(by: Profile.sorting)
    }

    var canReportIssue: Bool {
        AppCommandLine.contains(.withReportIssue) ||
            iapObservable.isEligibleForFeedback ||
            appConfiguration.distributionTarget.canAlwaysReportIssue ||
            isUsingExperimentalFeatures
    }

    var isUsingExperimentalFeatures: Bool {
        !configObservable.activeFlags.isDisjoint(with: [
            .neSocketUDP,
            .neSocketTCP
        ])
    }

    func computedTunnelLogs() async -> [ABI.LogEntry] {
        await (availableTunnelLogs ?? defaultTunnelLogs)()
    }

    func defaultTunnelLogs() async -> [ABI.LogEntry] {
        let url = appConfiguration.urlForTunnelLog
        return await Task.detached {
            pspLogEntriesAvailable(at: url)
        }.value
    }

    func removeTunnelLog(at url: URL) {
        guard let firstIndex = tunnelLogs.firstIndex(where: { $0.url == url }) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
        tunnelLogs.remove(at: firstIndex)
    }

    func removeTunnelLogs(at offsets: IndexSet) {
        offsets.forEach {
            try? FileManager.default.removeItem(at: tunnelLogs[$0].url)
        }
        tunnelLogs.remove(atOffsets: offsets)
    }

    func removeTunnelLogs() {
        pspLogEntriesPurge(at: appConfiguration.urlForTunnelLog)
        Task {
            tunnelLogs = await computedTunnelLogs()
        }
    }
}

#Preview {
    DiagnosticsView(profileObservable: .forPreviews, tunnel: .forPreviews) {
        [
            .init(date: Date(), url: URL(fileURLWithPath: "one.com")),
            .init(date: Date().addingTimeInterval(-60), url: URL(fileURLWithPath: "two.com")),
            .init(date: Date().addingTimeInterval(-600), url: URL(fileURLWithPath: "three.com"))
        ]
    }
    .withMockEnvironment()
}
