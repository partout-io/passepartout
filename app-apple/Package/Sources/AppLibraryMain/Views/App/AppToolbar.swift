// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct AppToolbar: ToolbarContent, SizeClassProviding {

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    let profileManager: ProfileManager

    let registry: Registry

    @Binding
    var layout: ProfilesLayout

    @Binding
    var isImporting: Bool

    let onSettings: () -> Void

    let onMigrateProfiles: () -> Void

    let onNewProfile: (EditableProfile) -> Void

    var body: some ToolbarContent {
        if isBigDevice {
            ToolbarItemGroup {
                addProfileMenu
                settingsButton
                layoutPicker
            }
        } else {
            ToolbarItem(placement: .navigation) {
                settingsButton
            }
            ToolbarItem(placement: .primaryAction) {
                addProfileMenu
            }
        }
    }
}

private extension AppToolbar {
    var addProfileMenu: some View {
        AddProfileMenu(
            profileManager: profileManager,
            registry: registry,
            isImporting: $isImporting,
            onMigrateProfiles: onMigrateProfiles,
            onNewProfile: onNewProfile
        )
    }

    var settingsButton: some View {
        Button(action: onSettings) {
            ThemeImage(.settings)
        }
    }

    var layoutPicker: some View {
        ProfilesLayoutPicker(layout: $layout)
    }
}

#Preview {
    NavigationStack {
        Text("AppToolbar")
            .toolbar {
                AppToolbar(
                    profileManager: .forPreviews,
                    registry: Registry(),
                    layout: .constant(.list),
                    isImporting: .constant(false),
                    onSettings: {},
                    onMigrateProfiles: {},
                    onNewProfile: { _ in }
                )
            }
            .frame(width: 600, height: 400)
    }
    .withMockEnvironment()
}
