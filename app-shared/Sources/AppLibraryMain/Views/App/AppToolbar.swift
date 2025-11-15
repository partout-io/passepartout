// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct AppToolbar: ToolbarContent, SizeClassProviding {

    @Environment(\.horizontalSizeClass)
    var hsClass

    @Environment(\.verticalSizeClass)
    var vsClass

    let profileManager: ProfileManager

    let registry: Registry

    @Binding
    var layout: ABI.ProfilesLayout

    @Binding
    var importAction: AddProfileMenu.Action?

    let onSettings: () -> Void

    let onNewProfile: (ABI.EditableProfile) -> Void

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
            importAction: $importAction,
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
                    importAction: .constant(nil),
                    onSettings: {},
                    onNewProfile: { _ in }
                )
            }
            .frame(width: 600, height: 400)
    }
    .withMockEnvironment()
}
