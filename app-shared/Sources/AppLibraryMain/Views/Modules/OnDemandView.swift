// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct OnDemandView: View, ModuleDraftEditing {

    @Environment(Theme.self)
    private var theme

    @Environment(\.distributionTarget)
    private var distributionTarget

    @ObservedObject
    var draft: ModuleDraft<OnDemandModule.Builder>

    @State
    private var paywallReason: PaywallReason?

    private let wifi: Wifi

    init(
        draft: ModuleDraft<OnDemandModule.Builder>,
        parameters: ModuleViewParameters,
        observer: WifiObserver? = nil
    ) {
        self.draft = draft
        wifi = Wifi(observer: observer ?? CoreLocationWifiObserver())
    }

    var body: some View {
        Group {
            rulesArea
        }
        .moduleView(draft: draft)
        .modifier(ModuleDynamicPaywallModifier(reason: $paywallReason))
    }
}

private extension OnDemandView {
    var allPolicies: [OnDemandModule.Policy] {
        if distributionTarget.supportsPaidFeatures {
            return [.any, .excluding, .including]
        } else {
            return [.any]
        }
    }

    @ViewBuilder
    var rulesArea: some View {
        policySection
        if draft.module.policy != .any {
            networkSection
            wifiSection
        }
    }

    var policySection: some View {
        Picker(selection: $draft.module.policy) {
            ForEach(allPolicies, id: \.self) {
                Text($0.localizedDescription)
            }
        } label: {
            HStack {
                Text(Strings.Modules.OnDemand.policy)
                PurchaseRequiredView(
                    for: draft.module,
                    reason: $paywallReason
                )
            }
        }
        .themeContainerWithSingleEntry(footer: policyFooterDescription)
    }

    var policyFooterDescription: String {
        let suffix: String
        switch draft.module.policy {
        case .any:
            suffix = Strings.Modules.OnDemand.Policy.Footer.any

        case .including, .excluding:
            if draft.module.policy == .including {
                suffix = Strings.Modules.OnDemand.Policy.Footer.including
            } else {
                suffix = Strings.Modules.OnDemand.Policy.Footer.excluding
            }

        @unknown default:
            suffix = Strings.Modules.OnDemand.Policy.Footer.any
        }
        return Strings.Modules.OnDemand.Policy.footer(suffix)
    }

    var networkSection: some View {
        Group {
            Toggle(Strings.Modules.OnDemand.mobile, isOn: $draft.module.withMobileNetwork)
            Toggle("\(Strings.Modules.OnDemand.ethernet) (Mac/TV)", isOn: $draft.module.withEthernetNetwork)
        }
        .themeSection(
            header: Strings.Global.Nouns.networks,
            footer: Strings.Modules.OnDemand.Networks.footer
        )
    }

    var wifiSection: some View {
        theme.listSection(
            Strings.Unlocalized.wifi,
            addTitle: Strings.Modules.OnDemand.Ssid.add,
            originalItems: allSSIDs,
            emptyValue: {
                do {
                    return try await wifi.currentSSID()
                } catch {
                    return ""
                }
            },
            itemLabel: { isEditing, binding in
                if isEditing {
                    Text(binding.wrappedValue)
                } else {
                    HStack {
                        ThemeTextField("", text: binding, placeholder: Strings.Placeholders.OnDemand.ssid)
                            .frame(maxWidth: .infinity)
                        Spacer()
                        Toggle("", isOn: isSSIDOn(binding.wrappedValue))
                    }
                    .labelsHidden()
                }
            }
        )
    }
}

private extension OnDemandView {
    var allSSIDs: Binding<[String]> {
        .init {
            Array(draft.module.withSSIDs.keys)
        } set: { newValue in
            draft.module.withSSIDs.forEach {
                guard newValue.contains($0.key) else {
                    draft.module.withSSIDs.removeValue(forKey: $0.key)
                    return
                }
            }
            newValue.forEach {
                guard draft.module.withSSIDs[$0] == nil else {
                    return
                }
                draft.module.withSSIDs[$0] = false
            }
        }
    }

    var onSSIDs: Binding<Set<String>> {
        .init {
            Set(draft.module.withSSIDs.filter {
                $0.value
            }.map(\.key))
        } set: { newValue in
            draft.module.withSSIDs.forEach {
                guard newValue.contains($0.key) else {
                    if draft.module.withSSIDs[$0.key] != nil {
                        draft.module.withSSIDs[$0.key] = false
                    } else {
                        draft.module.withSSIDs.removeValue(forKey: $0.key)
                    }
                    return
                }
            }
            newValue.forEach {
                guard !(draft.module.withSSIDs[$0] ?? false) else {
                    return
                }
                draft.module.withSSIDs[$0] = true
            }
        }
    }

    func isSSIDOn(_ ssid: String) -> Binding<Bool> {
        .init {
            draft.module.withSSIDs[ssid] ?? false
        } set: {
            draft.module.withSSIDs[ssid] = $0
        }
    }
}

private extension OnDemandView {
    func requestSSID(_ text: Binding<String>) {
        Task { @MainActor in
            let ssid = try await wifi.currentSSID()
            if !draft.module.withSSIDs.keys.contains(ssid) {
                text.wrappedValue = ssid
            }
        }
    }
}

// MARK: - Previews

#Preview {
    var module = OnDemandModule.Builder()
    module.policy = .excluding
    module.withMobileNetwork = true
    module.withSSIDs = [
        "One": true,
        "Two": false,
        "Three": false
    ]
    return module.preview()
//    return module.preview {
//        OnDemandView(
//            draft: $1[$0],
//            parameters: .init(
//                registry: Registry(),
//                editor: $1,
//                impl: nil
//            ),
//            observer: MockWifi()
//        )
//    }
}

private class MockWifi: WifiObserver {
    func currentSSID() async throws -> String {
        ""
    }
}
