// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import SwiftUI

struct SystemExtensionView: View {
    var body: some View {
        Form {
            Text(Strings.Views.Settings.SystemExtension.message(
                Strings.Unlocalized.appName,
                Strings.Global.Nouns.Apple.systemExtension,
                Strings.Global.Nouns.Apple.networkExtensions,
                Strings.Unlocalized.appName
            ))
            Link(Strings.Views.Settings.SystemExtension.Buttons.open, destination: SystemExtensionManager.preferencesURL)
        }
        .themeForm()
    }
}

#Preview {
    SystemExtensionView()
}

#endif
