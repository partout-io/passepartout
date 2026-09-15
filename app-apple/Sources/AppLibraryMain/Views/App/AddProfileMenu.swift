// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct AddProfileMenu: View {
    enum Action {
        case importFile
        case importQR
        case importText
    }

    @Environment(\.appConfiguration)
    private var appConfiguration

    let profileObservable: ProfileObservable

    @Binding
    var importAction: Action?

    let onNewProfile: (EditableProfile) -> Void

    var body: some View {
        Menu {
            emptyProfileButton
            importFileButton
#if os(iOS)
            importQRButton
#endif
            importTextButton
        } label: {
            ThemeImage(.add)
        }
    }
}

private extension AddProfileMenu {
    var emptyProfileButton: some View {
        Button {
            let editable = EditableProfile(name: newName)
            onNewProfile(editable)
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.NewProfile.empty, .profileEdit)
        }
    }

    var importFileButton: some View {
        Button {
            importAction = .importFile
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.importFile.forMenu, .profileImportFile)
        }
    }

    var importQRButton: some View {
        Button {
            importAction = .importQR
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.ImportQr.title.forMenu, .profileImportQR)
        }
    }

    var importTextButton: some View {
        Button {
            importAction = .importText
        } label: {
            ThemeImageLabel(Strings.Views.App.Toolbar.ImportText.title.forMenu, .profileImportText)
        }
    }
}

private extension AddProfileMenu {
    var newName: String {
        profileObservable.firstUniqueName(from: Strings.Placeholders.Profile.name)
    }
}
