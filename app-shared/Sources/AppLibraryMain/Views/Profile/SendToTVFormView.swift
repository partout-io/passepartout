// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

struct SendToTVFormView: View {

    @Binding
    var addressPort: HTTPAddressPort

    var passcode: Binding<String>?

    var body: some View {
        Form {
            urlSection
            passcodeSection
        }
        .themeForm()
        .navigationTitle(Strings.Views.Profile.SendTv.title_compound)
    }
}

private extension SendToTVFormView {
    var urlSection: some View {
        Group {
            ThemeTextField(Strings.Global.Nouns.address, text: $addressPort.address, placeholder: Strings.Unlocalized.Placeholders.ipAddress(forFamily: .v4))
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            ThemeTextField(Strings.Global.Nouns.port, text: $addressPort.port, placeholder: Strings.Unlocalized.Placeholders.webUploaderPort)
            Text(Strings.Unlocalized.url)
                .themeTrailingValue(addressPort.urlDescription)
        }
        .themeSection(footer: Strings.Views.Profile.SendTv.Form.message(
            Strings.Global.Nouns.profiles,
            Strings.Views.Tv.Profiles.importLocal,
            Strings.Unlocalized.appleTV
        ))
    }

    var passcodeSection: some View {
        passcode.map { text in
            Group {
                ThemeTextField(Strings.Global.Nouns.passcode, text: text, placeholder: Strings.Unlocalized.Placeholders.webUploaderPasscode)
            }
            .themeSection()
        }
    }
}

#Preview {
    struct FormPreview: View {

        @State
        private var addressPort = HTTPAddressPort()

        @State
        private var passcode = ""

        var body: some View {
            SendToTVFormView(
                addressPort: $addressPort,
                passcode: $passcode
            )
        }
    }

    return FormPreview()
}
