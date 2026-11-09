// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct ProfileShareButton: View {
    @Environment(\.appImportExport)
    private var appImportExport

    @Environment(IAPObservable.self)
    private var iapObservable

    private let profile: Profile?

    init(profile: Profile?) {
        self.profile = profile
    }

    init(editor: ProfileEditor) {
        do {
            let profile = try editor.profile.builder().build()
            self.init(profile: profile)
        } catch {
            pspLog(.profiles, .debug, "Unable to build profile from editor: \(error)")
            self.init(profile: nil)
        }
    }

    var body: some View {
        let items = profile.map { profile in
            [ProfileRepresentation(name: profile.name) { [appImportExport, profile] in
                try Self.toURL(profile: profile, appImportExport: appImportExport)
            }]
        } ?? []
        return ShareLink(
            items: items,
            preview: { .init($0.name) },
            label: shareLabel
        )
        .disabled(profile == nil || !iapObservable.isEligible(for: .sharing))
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

    nonisolated static func toURL(profile: Profile, appImportExport: AppImportExport) throws -> URL {
        do {
            pspLog(.profiles, .debug, "Writing profile \(profile.id) for sharing...")
            let url = try appImportExport.writeToURL(profile)
            pspLog(.profiles, .debug, "Written profile to: \(url)")
            return url
        } catch {
            pspLog(.profiles, .error, "Unable to write profile \(profile.id): \(error)")
            throw error
        }
    }
}

private struct ProfileRepresentation: Transferable {
    let name: String

    let encoder: @Sendable () throws -> URL

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { subject in
            try subject.encoder()
        }
    }
}
