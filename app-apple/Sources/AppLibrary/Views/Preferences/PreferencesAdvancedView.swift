// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct PreferencesAdvancedView: View {
    @Environment(ConfigObservable.self)
    private var configObservable

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
        .neSocketUDP,
        .neSocketTCP,
        .wgV4OverV6
    ]

    static func description(for flag: ABI.ConfigFlag) -> String {
        let V = Strings.Entities.Ui.ConfigFlag.self
        switch flag {
        case .neSocketUDP:
            return V.neSocketUDP
        case .neSocketTCP:
            return V.neSocketTCP
        case .wgV4OverV6:
            return "WireGuard IPv4 > IPv6"
        default:
            assertionFailure()
            return ""
        }
    }

    var remoteSection: some View {
        ForEach(Self.flags, id: \.rawValue) { flag in
            Toggle(isOn: isOnBinding(for: flag)) {
                flagView(for: flag)
            }
        }
        .themeSection(
            header: Strings.Global.Actions.allow,
            footer: Strings.Views.Preferences.Advanced.Remote.footer
        )
    }

    func isOnBinding(for flag: ABI.ConfigFlag) -> Binding<Bool> {
        Binding<Bool> {
            experimental.isUsed(flag)
        } set: {
            experimental.setUsed(flag, isUsed: $0)
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
    func isUsed(_ flag: ABI.ConfigFlag) -> Bool {
        !ignoredConfigFlags.contains(flag)
    }

    mutating func setUsed(_ flag: ABI.ConfigFlag, isUsed: Bool) {
        if isUsed {
            ignoredConfigFlags.remove(flag)
        } else {
            ignoredConfigFlags.insert(flag)
        }
    }
}
