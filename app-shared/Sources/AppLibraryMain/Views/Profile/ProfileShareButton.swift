// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileShareButton: View {

    @EnvironmentObject
    private var registryCoder: RegistryCoder

    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    init?(editor: ProfileEditor) {
        do {
            let profile = try editor.profile.builder().build()
            self.init(profile: profile)
        } catch {
            pp_log_g(.App.profiles, .error, "Unable to build profile from editor: \(error)")
            return nil
        }
    }

    var body: some View {
        ShareLink(
            item: ProfileRepresentation(encoder: toURL),
            preview: .init(profile.name),
            label: shareLabel
        )
    }
}

private extension ProfileShareButton {
    func shareLabel() -> some View {
#if os(iOS)
        Text(Strings.Views.Profile.Buttons.share)
#else
        ThemeImage(.share)
#endif
    }

    func toURL() throws -> URL {
        do {
            pp_log_g(.App.profiles, .debug, "Writing profile \(profile.id) for sharing...")
            let url = try profile.writeToURL(coder: registryCoder)
            pp_log_g(.App.profiles, .debug, "Written profile to: \(url)")
            return url
        } catch {
            pp_log_g(.App.profiles, .error, "Unable to write profile \(profile.id): \(error)")
            throw error
        }
    }
}

private struct ProfileRepresentation: Transferable {
    let encoder: () throws -> URL

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { subject in
            try subject.encoder()
        }
    }
}
