// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileShareButton: View {

    @EnvironmentObject
    private var registryCoder: RegistryCoder

    @ObservedObject
    var editor: ProfileEditor

    var body: some View {
        ShareLink(
            item: ProfileRepresentation(encoder: toURL),
            preview: .init(editor.profile.name),
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
            pp_log_g(.App.profiles, .debug, "Writing profile \(editor.profile.id) for sharing...")
            let url = try editor.writeToURL(coder: registryCoder)
            pp_log_g(.App.profiles, .debug, "Written profile to: \(url)")
            return url
        } catch {
            pp_log_g(.App.profiles, .error, "Unable to write profile \(editor.profile.id): \(error)")
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
