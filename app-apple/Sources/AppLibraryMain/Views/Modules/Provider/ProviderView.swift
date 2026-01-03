// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProviderView: View, ModuleDraftEditing {

    @EnvironmentObject
    private var apiManager: APIManager

    @EnvironmentObject
    private var preferencesManager: PreferencesManager

    @ObservedObject
    var draft: ModuleDraft<ProviderModule.Builder>

    private let registry: Registry

    @StateObject
    private var providerPreferences = ProviderPreferences()

    @State
    private var availablePresets: [ProviderPreset] = []

    @State
    private var paywallReason: PaywallReason?

    init(draft: ModuleDraft<ProviderModule.Builder>, parameters: ModuleViewParameters) {
        self.draft = draft
        registry = parameters.registry
    }

    var body: some View {
        debugChanges()
        return contentView
            .moduleView(draft: draft)
            .modifier(ModuleDynamicPaywallModifier(reason: $paywallReason))
            .onLoad(perform: loadCurrentProvider)
            .onChange(of: providerId, perform: onChangeProvider)
            .onChange(of: providerEntity, perform: onChangeEntity)
            .onDisappear(perform: savePreferences)
            .disabled(apiManager.isLoading)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.draft.module.providerId == rhs.draft.module.providerId
    }
}

// MARK: - Content

private extension ProviderView {

    @ViewBuilder
    var contentView: some View {
        providerSection
        if providerType != nil {
            targetSection
        }
        if providerId != nil {
            optionsSection
        }
    }

    var providerSection: some View {
        Group {
            providerPicker
            moduleTypePicker
        }
        .themeSection()
    }

#if os(iOS)
    var targetSection: some View {
        Group {
            serverLink
            presetPicker
            module.map { module in
                RefreshInfrastructureButton(module: module)
            }
        }
        .themeSection(footer: lastUpdatedString)
    }
#else
    var targetSection: some View {
        Group {
            serverLink
            presetPicker
            module.map { module in
                HStack {
                    lastUpdatedString.map {
                        Text($0)
                            .themeSubtitle()
                    }
                    Spacer()
                    RefreshInfrastructureButton(module: module)
                }
            }
        }
        .themeSection()
    }
#endif

    var providerPicker: some View {
        ProviderPicker(
            providers: supportedProviders,
            providerId: $draft.module.providerId,
            isLoading: apiManager.isLoading,
            paywallReason: $paywallReason
        )
    }

    var moduleTypePicker: some View {
        Picker(Strings.Views.Providers.module, selection: $draft.module.providerModuleType) {
            Text(Strings.Views.Providers.selectModule)
                .tag(nil as ModuleType?)
            ForEach(supportedTypes, id: \.rawValue) {
                Text($0.localizedDescription)
                    .tag($0 as ModuleType?)
            }
        }
    }

    var serverLink: some View {
        ProviderServerLink(entity: providerEntity)
    }

    var presetPicker: some View {
        Picker(Strings.Views.Providers.preset, selection: presetIdBinding) {
            if draft.module.entity == nil {
                Text(Strings.Views.Providers.Preset.placeholder)
                    .tag(nil as String?)
            }
            ForEach(availablePresets, id: \.presetId) {
                Text($0.description)
                    .tag($0.presetId as String?)
            }
        }
        .disabled(draft.module.entity == nil)
    }

    var optionsSection: some View {
        Group {
            switch providerType {
            case .openVPN:
                OpenVPNCredentialsLink()
                resolvedModuleLink
            case .wireGuard:
                // TODO: #507, WireGuard provider private key
                EmptyView()
            default:
                EmptyView()
            }
        }
        .themeSection(header: optionsHeader)
    }

    var optionsHeader: String? {
        guard let providerType else {
            return nil
        }
        switch providerType {
        case .openVPN:
            return providerType.localizedDescription
        default:
            return nil
        }
    }

    var resolvedModuleLink: some View {
        resolvedModule.map { module in
            NavigationLink(Strings.Global.Nouns.configuration) {
                if let ovpn = module as? OpenVPNModule,
                   let configuration = ovpn.configuration?.builder() {
                    OpenVPNConfigurationView(configuration: configuration)
                }
            }
        }
    }
}

private extension ProviderView {

    // FIXME: #1470, heavy data copy in SwiftUI
    var module: ProviderModule? {
        try? draft.module.build()
    }

    var providerId: ProviderID? {
        draft.module.providerId
    }

    var provider: Provider? {
        providerId.map {
            apiManager.provider(withId: $0)
        } ?? nil
    }

    var providerType: ModuleType? {
        draft.module.providerModuleType
    }

    // FIXME: #1470, heavy data copy in SwiftUI
    var providerEntity: ProviderEntity? {
        draft.module.entity
    }

    var supportedProviders: [Provider] {
        apiManager.providers
    }

    var supportedTypes: [ModuleType] {
        provider?.metadata.keys.sorted() ?? []
    }

    var presetIdBinding: Binding<String?> {
        Binding {
            draft.module.entity?.preset.presetId
        } set: {
            guard let entity = draft.module.entity,
                  let presetId = $0,
                  let preset = availablePresets.first(where: { $0.presetId == presetId }) else {
                return
            }
            draft.module.entity = ProviderEntity(
                server: entity.server,
                preset: preset,
                heuristic: entity.heuristic
            )
        }
    }

    var resolvedModule: Module? {
        do {
            let module = try draft.module.build()
            return try registry.resolvedModule(module, in: nil)
        } catch {
            pp_log_g(.App.core, .debug, "Unable to resolve provider module: \(error)")
            return nil
        }
    }

    var lastUpdate: Date? {
        guard let providerId else {
            return nil
        }
        return apiManager.cache(for: providerId)?.lastUpdate.map(\.date)
    }

    var lastUpdatedString: String? {
        guard let lastUpdate else {
            return apiManager.isLoading ? Strings.Views.Providers.LastUpdated.loading : nil
        }
        return Strings.Views.Providers.lastUpdated(lastUpdate.localizedDescription(style: .timestamp))
    }

    func loadCurrentProvider() {
       Task {
           if let providerId {
               loadPreferences(for: providerId)
               if let providerEntity {
                   await loadSupportedPresets(for: providerEntity.server)
               }
           }
           await refreshIndex()
       }
    }

    func refreshIndex() async {
        do {
            try await apiManager.fetchIndex()
        } catch {
            pp_log_g(.App.core, .error, "Unable to fetch index: \(error)")
        }
    }

    func refreshInfrastructure(for newProviderModule: ProviderModule) async {
        do {
            try await apiManager.fetchInfrastructure(for: newProviderModule)
        } catch {
            pp_log_g(.App.core, .error, "Unable to refresh infrastructure: \(error)")
        }
    }

    func loadSupportedPresets(for server: ProviderServer) async {
        guard let providerType else {
            return
        }
        do {
            availablePresets = try await apiManager.presets(for: server, moduleType: providerType)
        } catch {
            pp_log_g(.App.core, .error, "Unable to fetch presets for current server: \(error)")
            availablePresets = []
        }
    }

    func onChangeProvider(_: ProviderID?) {
       Task {
           if let module {
               await refreshInfrastructure(for: module)
               loadPreferences(for: module.providerId)
           } else {
               loadPreferences(for: nil)
           }
       }
    }

    func onChangeEntity(_ newEntity: ProviderEntity?) {
        guard let newEntity else {
            return
        }
        Task {
            await loadSupportedPresets(for: newEntity.server)
        }
    }

    func loadPreferences(for newProviderId: ProviderID?) {
        if let newProviderId {
            do {
                pp_log_g(.App.core, .debug, "Load preferences for provider \(newProviderId)")
                let repository = try preferencesManager.preferencesRepository(forProviderWithId: newProviderId)
                providerPreferences.setRepository(repository)
            } catch {
                pp_log_g(.App.core, .error, "Unable to load preferences for provider \(newProviderId): \(error)")
                providerPreferences.setRepository(nil)
            }
        } else {
            providerPreferences.setRepository(nil)
        }
    }

    func savePreferences() {
        guard let providerId else {
            return
        }
        do {
            pp_log_g(.App.core, .debug, "Save preferences for provider \(providerId)")
            try providerPreferences.save()
        } catch {
            pp_log_g(.App.core, .error, "Unable to save preferences for provider \(providerId): \(error)")
        }
    }
}

// MARK: - Previews

#Preview {
    var module = ProviderModule.Builder()
    module.providerId = .hideme
    return module.preview()
}
