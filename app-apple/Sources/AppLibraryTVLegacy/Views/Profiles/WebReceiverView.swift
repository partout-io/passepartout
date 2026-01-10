// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct WebReceiverView: View {

    @ObservedObject
    var webReceiverManager: WebReceiverManager

    let registry: Registry

    @ObservedObject
    var profileManager: ProfileManager

    let errorHandler: ErrorHandler

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
    func view(forWebsite website: ABI.WebsiteWithPasscode) -> some View {
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
                try await profileManager.legacyImport(
                    .contents(filename: file.name, data: file.contents),
                    registry: registry,
                    sharingFlag: .tv
                )
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
