// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct ProfileBehaviorSection: View {
    let profileEditor: ProfileEditor

    var body: some View {
        Group {
            keepAliveToggle
            enforceTunnelToggle
        }
        .themeContainer(header: Strings.Modules.General.Sections.Behavior.header)
    }
}

private extension ProfileBehaviorSection {
    var keepAliveToggle: some View {
        Toggle(Strings.Modules.General.Rows.keepAliveOnSleep, isOn: profileEditor.binding(\.keepsAliveOnSleep))
            .themeContainerEntry(
                header: Strings.Modules.General.Sections.Behavior.header,
                subtitle: Strings.Modules.General.Rows.KeepAliveOnSleep.footer
            )
    }

    var enforceTunnelToggle: some View {
        Toggle(Strings.Modules.General.Rows.enforceTunnel, isOn: profileEditor.binding(\.enforceTunnel))
            .themeContainerEntry(subtitle: Strings.Modules.General.Rows.EnforceTunnel.footer)
    }
}

#Preview {
    Form {
        ProfileBehaviorSection(profileEditor: ProfileEditor())
    }
    .themeForm()
    .withMockEnvironment()
}
