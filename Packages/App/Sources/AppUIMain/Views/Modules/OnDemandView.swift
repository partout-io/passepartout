//
//  OnDemandView.swift
//  Passepartout
//
//  Created by Davide De Rosa on 2/23/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import CommonLibrary
import CommonUtils
import PassepartoutKit
import SwiftUI

struct OnDemandView: View, ModuleDraftEditing {

    @EnvironmentObject
    private var theme: Theme

    let module: OnDemandModule.Builder

    @ObservedObject
    var editor: ProfileEditor

    @State
    private var paywallReason: PaywallReason?

    private let wifi: Wifi

    init(
        module: OnDemandModule.Builder,
        parameters: ModuleViewParameters,
        observer: WifiObserver? = nil
    ) {
        self.module = module
        editor = parameters.editor
        wifi = Wifi(observer: observer ?? CoreLocationWifiObserver())
    }

    var body: some View {
        Group {
            enabledSection
            rulesArea
        }
        .moduleView(editor: editor, draft: draft.wrappedValue)
        .modifier(PaywallModifier(reason: $paywallReason))
    }
}

private extension OnDemandView {
    static let allPolicies: [OnDemandModule.Policy] = [
        .any,
        .excluding,
        .including
    ]

    var enabledSection: some View {
        Section {
            Toggle(Strings.Global.Nouns.enabled, isOn: draft.isEnabled)
        }
    }

    @ViewBuilder
    var rulesArea: some View {
        if draft.wrappedValue.isEnabled {
            policySection
            if draft.wrappedValue.policy != .any {
                networkSection
                wifiSection
            }
        }
    }

    var policySection: some View {
        Picker(selection: draft.policy) {
            ForEach(Self.allPolicies, id: \.self) {
                Text($0.localizedDescription)
            }
        } label: {
            HStack {
                Text(Strings.Modules.OnDemand.policy)
                PurchaseRequiredView(
                    for: module,
                    reason: $paywallReason
                )
            }
        }
        .themeSectionWithSingleRow(footer: policyFooterDescription)
    }

    var policyFooterDescription: String {
        guard draft.wrappedValue.isEnabled else {
            return "" // better animation than removing footer completely
        }
        let suffix: String
        switch draft.wrappedValue.policy {
        case .any:
            suffix = Strings.Modules.OnDemand.Policy.Footer.any

        case .including, .excluding:
            if draft.wrappedValue.policy == .including {
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
            Toggle(Strings.Modules.OnDemand.mobile, isOn: draft.withMobileNetwork)
            Toggle("\(Strings.Modules.OnDemand.ethernet) (Mac/TV)", isOn: draft.withEthernetNetwork)
        }
        .themeSection(
            header: Strings.Global.Nouns.networks,
            footer: Strings.Modules.OnDemand.Networks.footer,
            forcesFooter: true
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
                            .themeManualInput()
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
            Array(draft.wrappedValue.withSSIDs.keys)
        } set: { newValue in
            draft.wrappedValue.withSSIDs.forEach {
                guard newValue.contains($0.key) else {
                    draft.wrappedValue.withSSIDs.removeValue(forKey: $0.key)
                    return
                }
            }
            newValue.forEach {
                guard draft.wrappedValue.withSSIDs[$0] == nil else {
                    return
                }
                draft.wrappedValue.withSSIDs[$0] = false
            }
        }
    }

    var onSSIDs: Binding<Set<String>> {
        .init {
            Set(draft.wrappedValue.withSSIDs.filter {
                $0.value
            }.map(\.key))
        } set: { newValue in
            draft.wrappedValue.withSSIDs.forEach {
                guard newValue.contains($0.key) else {
                    if draft.wrappedValue.withSSIDs[$0.key] != nil {
                        draft.wrappedValue.withSSIDs[$0.key] = false
                    } else {
                        draft.wrappedValue.withSSIDs.removeValue(forKey: $0.key)
                    }
                    return
                }
            }
            newValue.forEach {
                guard !(draft.wrappedValue.withSSIDs[$0] ?? false) else {
                    return
                }
                draft.wrappedValue.withSSIDs[$0] = true
            }
        }
    }

    func isSSIDOn(_ ssid: String) -> Binding<Bool> {
        .init {
            draft.wrappedValue.withSSIDs[ssid] ?? false
        } set: {
            draft.wrappedValue.withSSIDs[ssid] = $0
        }
    }
}

private extension OnDemandView {
    func requestSSID(_ text: Binding<String>) {
        Task { @MainActor in
            let ssid = try await wifi.currentSSID()
            if !draft.wrappedValue.withSSIDs.keys.contains(ssid) {
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
    return module.preview {
        OnDemandView(
            module: $0,
            parameters: .init(
                editor: $1,
                preferences: ModulePreferences(),
                impl: nil
            ),
            observer: MockWifi()
        )
    }
}

private class MockWifi: WifiObserver {
    func currentSSID() async throws -> String {
        ""
    }
}
