// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import CommonResources
import SwiftUI

struct DiagnosticsView: View {
    struct LogEntry: Identifiable, Equatable {
        let date: Date

        let url: URL

        var id: Date {
            date
        }
    }

    @Environment(Theme.self)
    private var theme

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var iapManager: IAPManager

    @EnvironmentObject
    private var kvManager: KeyValueManager

    @Environment(\.distributionTarget)
    private var distributionTarget

    @EnvironmentObject
    private var configManager: ConfigManager

    let profileManager: ProfileManager

    let tunnel: ExtendedTunnel

    var availableTunnelLogs: (() async -> [LogEntry])?

    @State
    private var logsPrivateData = false

    @State
    private var tunnelLogs: [LogEntry] = []

    @State
    var isPresentingUnableToEmail = false

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = Resources.constants.formats.timestamp
        return df
    }()

    var body: some View {
        Form {
            if iapManager.isBeta {
                BetaSection()
            }
            liveLogSection
            profilesSection
            if distributionTarget.supportsAppGroups {
                tunnelLogsSection
            }
            if canReportIssue {
                reportIssueSection
            }
        }
        .task {
            tunnelLogs = await computedTunnelLogs()
        }
        .themeKeyValue(kvManager, ABI.AppPreference.logsPrivateData.key, $logsPrivateData, default: false)
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
                purchasedProducts: iapManager.purchasedProducts,
                isUnableToEmail: $isPresentingUnableToEmail
            )
        }
    }

    func logView(for item: LogEntry) -> some View {
        ThemeRemovableItemRow(isEditing: true) {
            let dateString = dateFormatter.string(from: item.date)
            navLink(dateString, to: .tunnelLog(title: dateString, url: item.url))
        } removeAction: {
            removeTunnelLog(at: item.url)
        }
    }

    func navLink(_ title: String, to value: DiagnosticsRoute) -> some View {
        NavigationLink(title, value: value)
    }
}

private extension DiagnosticsView {
    var activeProfiles: [Profile] {
        tunnel.activeProfiles
            .values
            .compactMap {
                profileManager.partoutProfile(withId: $0.id)
            }
            .sorted(by: Profile.sorting)
    }

    var canReportIssue: Bool {
        AppCommandLine.contains(.withReportIssue) ||
            iapManager.isEligibleForFeedback ||
            distributionTarget.canAlwaysReportIssue ||
            isUsingExperimentalFeatures
    }

    var isUsingExperimentalFeatures: Bool {
        !configManager.activeFlags.isDisjoint(with: [
            .neSocketUDP,
            .neSocketTCP
        ])
    }

    func computedTunnelLogs() async -> [LogEntry] {
        await (availableTunnelLogs ?? defaultTunnelLogs)()
    }

    func defaultTunnelLogs() async -> [LogEntry] {
        let target = distributionTarget
        return await Task.detached {
            LocalLogger.FileStrategy()
                .availableLogs(at: Resources.constants.bundleURLForTunnelLog(in: target))
                .sorted {
                    $0.key > $1.key
                }
                .map {
                    LogEntry(date: $0, url: $1)
                }
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
        LocalLogger.FileStrategy()
            .purgeLogs(at: Resources.constants.bundleURLForTunnelLog(in: distributionTarget))
        Task {
            tunnelLogs = await computedTunnelLogs()
        }
    }
}

#Preview {
    DiagnosticsView(profileManager: .forPreviews, tunnel: .forPreviews) {
        [
            .init(date: Date(), url: URL(string: "http://one.com")!),
            .init(date: Date().addingTimeInterval(-60), url: URL(string: "http://two.com")!),
            .init(date: Date().addingTimeInterval(-600), url: URL(string: "http://three.com")!)
        ]
    }
    .withMockEnvironment()
}
