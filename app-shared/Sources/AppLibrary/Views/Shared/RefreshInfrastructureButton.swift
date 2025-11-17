// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
import CommonLibrary
import Partout
import SwiftUI

public struct RefreshInfrastructureButton<Label>: View where Label: View {

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var kvManager: KeyValueManager

    @Environment(\.appConfiguration)
    private var appConfiguration

    private let module: ProviderModule

    private let label: () -> Label

    @State
    private var elapsed: TimeInterval = .infinity

    public init(module: ProviderModule, label: @escaping () -> Label) {
        self.module = module
        self.label = label
    }

    public var body: some View {
        Button {
            Task {
                try await apiManager.fetchInfrastructure(for: module)
                saveLastUpdate()
            }
        } label: {
            label()
        }
        .disabled(!isEnabled)
        .task {
            loadLastUpdate()
        }
        .onChange(of: elapsed) {
            pp_log_g(.App.core, .info, "Elapsed since last update of \(module.providerId): \($0)")
        }
    }
}

extension RefreshInfrastructureButton where Label == RefreshInfrastructureButtonProgressView {
    public init(module: ProviderModule) {
        self.module = module
        label = {
            RefreshInfrastructureButtonProgressView()
        }
    }
}

public struct RefreshInfrastructureButtonProgressView: View {

    @EnvironmentObject
    private var apiManager: APIManager

    public var body: some View {
#if os(iOS)
        HStack {
            Text(Strings.Views.Providers.refreshInfrastructure)
            if apiManager.isLoading {
                Spacer()
                ProgressView()
            }
        }
#else
        Text(Strings.Views.Providers.refreshInfrastructure)
#endif
    }
}

private extension RefreshInfrastructureButton {
    var isEnabled: Bool {
        AppCommandLine.contains(.withoutRateLimits) || elapsed >= appConfiguration.constants.api.refreshInfrastructureRateLimit
    }

    func loadLastUpdate() {
        guard let map = kvManager.object(forUIPreference: .lastInfrastructureRefresh) as [String: TimeInterval]? else {
            elapsed = .infinity
            return
        }
        guard let lastUpdate = map[module.providerId.rawValue] else {
            elapsed = .infinity
            return
        }
        elapsed = Date.timeIntervalSinceReferenceDate - lastUpdate
    }

    func saveLastUpdate() {
        var map = kvManager.object(forUIPreference: .lastInfrastructureRefresh) as [String: TimeInterval]? ?? [:]
        map[module.providerId.rawValue] = Date.timeIntervalSinceReferenceDate
        kvManager.set(map, forUIPreference: .lastInfrastructureRefresh)
        elapsed = .zero
    }
}
