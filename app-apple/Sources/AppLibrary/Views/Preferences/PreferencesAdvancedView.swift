// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct PreferencesAdvancedView: View {
    @Environment(ConfigObservable.self)
    private var configObservable

    @Environment(IAPObservable.self)
    private var iapObservable

    @Binding
    var experimental: ABI.AppPreferenceValues.Experimental

    var body: some View {
        Form {
            remoteSection
        }
        .themeForm()
    }
}

private extension PreferencesAdvancedView {
    static let flags: [ABI.ConfigFlag] = [
        .bsdSockets,
        .newProfileEncoding,
        .ovpnCrossV2,
        .wgCrossV2
    ]

    static func description(for flag: ABI.ConfigFlag) -> String {
        switch flag {
        case .bsdSockets:
            return "BSD sockets"
        case .newProfileEncoding:
            return "New profile encoding"
        case .ovpnCrossV2:
            return "Cross-platform OpenVPN v2"
        case .wgCrossV2:
            return "Cross-platform WireGuard v2"
        default:
            assertionFailure()
            return ""
        }
    }

    var remoteSection: some View {
        ForEach(visibleFlags, id: \.rawValue) { flag in
            Toggle(isOn: isOnBinding(for: flag)) {
                flagView(for: flag)
            }
        }
        .themeSection(
            header: Strings.Global.Actions.allow,
            footer: Strings.Views.Preferences.Advanced.Remote.footer
        )
    }

    var visibleFlags: [ABI.ConfigFlag] {
        Self.flags.filter {
            iapObservable.isBeta || configObservable.isActive($0)
        }
    }

    func isOnBinding(for flag: ABI.ConfigFlag) -> Binding<Bool> {
        Binding {
            experimental.isUsed(
                flag,
                isActive: configObservable.isActive(flag)
            )
        } set: {
            experimental.setUsed(
                flag,
                isUsed: $0,
                isActive: configObservable.isActive(flag)
            )
        }
    }

    func flagView(for flag: ABI.ConfigFlag) -> some View {
        VStack(alignment: .leading) {
            Text(Self.description(for: flag))
            Text(configObservable.isActive(flag) ? Strings.Global.Nouns.enabled : Strings.Global.Nouns.disabled)
                .themeSubtitle()
        }
    }
}

private extension ABI.AppPreferenceValues.Experimental {
    func isUsed(
        _ flag: ABI.ConfigFlag,
        isActive: Bool
    ) -> Bool {
        if isActive {
            return !ignoredConfigFlags.contains(flag)
        }
        return enabledConfigFlags.contains(flag)
    }

    mutating func setUsed(
        _ flag: ABI.ConfigFlag,
        isUsed: Bool,
        isActive: Bool
    ) {
        ignoredConfigFlags.remove(flag)
        enabledConfigFlags.remove(flag)

        guard !isUsed else {
            if !isActive {
                enabledConfigFlags.insert(flag)
            }
            return
        }

        if isActive {
            ignoredConfigFlags.insert(flag)
        }
    }
}
