// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils
import SwiftUI

struct WebReceiverView: View {

    @EnvironmentObject
    private var registryCoder: RegistryCoder

    @ObservedObject
    var webReceiverManager: WebReceiverManager

    let registry: Registry

    @ObservedObject
    var profileManager: ProfileManager

    @ObservedObject
    var errorHandler: ErrorHandler

    var body: some View {
        VStack {
            if let website = webReceiverManager.website {
                view(forWebsite: website)
            } else {
                Text(Strings.Views.Tv.WebReceiver.toggle)
            }
        }
        .task(handleUploadedFile)
        .onDisappear {
            webReceiverManager.stop()
        }
    }
}

private extension WebReceiverView {
    func view(forWebsite website: WebReceiverManager.Website) -> some View {
        VStack {
            Text(Strings.Views.Tv.WebReceiver.qr)
            QRCodeView(text: website.url.absoluteString)
                .frame(width: 400)
                .padding(.vertical)

            VStack {
                Text(website.url.absoluteString)
                    .fontWeight(.bold)

                if let passcode = website.passcode {
                    HStack(spacing: .zero) {
                        Text("\(Strings.Global.Nouns.passcode): ")
                        Text(passcode)
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.title3)

            Spacer()
        }
    }
}

private extension WebReceiverView {

    @Sendable
    func handleUploadedFile() async {
        for await file in webReceiverManager.files {
            pp_log_g(.App.web, .info, "Uploaded: \(file.name), \(file.contents.count) bytes")
            do {
                let input: ProfileImporterInput = .contents(filename: file.name, data: file.contents)

                // TODO: #1512, import encrypted OpenVPN profiles over the web
                var profile = try registryCoder.profile(from: input, passphrase: nil)
                pp_log_g(.App.web, .info, "Import uploaded profile: \(profile)")

                var builder = profile.builder()
                builder.attributes.isAvailableForTV = true
                profile = try builder.build()
                try await profileManager.save(profile, isLocal: true)

                webReceiverManager.renewPasscode()
            } catch {
                pp_log_g(.App.web, .error, "Unable to import uploaded profile: \(error)")
                errorHandler.handle(error)
            }
        }
    }
}

// MARK: -

#Preview {
    WebReceiverView(
        webReceiverManager: .forPreviews,
        registry: Registry(),
        profileManager: .forPreviews,
        errorHandler: .default()
    )
    .task {
        try? WebReceiverManager.forPreviews.start()
    }
}
