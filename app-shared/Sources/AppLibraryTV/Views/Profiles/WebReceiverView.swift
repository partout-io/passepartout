// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct WebReceiverView: View {

    @Environment(ViewLogger.self)
    private var logger

    @ObservedObject
    var webReceiverManager: WebReceiverManager

    let profileObservable: ProfileObservable

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
            logger.log(.web, .info, "Uploaded: \(file.name), \(file.contents.count) bytes")
            do {
                // TODO: #1512, import encrypted OpenVPN profiles over the web
                try await profileObservable.import(.contents(filename: file.name, data: file.contents))
                webReceiverManager.renewPasscode()
            } catch {
                logger.log(.web, .error, "Unable to import uploaded profile: \(error)")
                errorHandler.handle(error)
            }
        }
    }
}

// MARK: -

// FIXME: #1594, Previews
//#Preview {
//    WebReceiverView(
//        webReceiverManager: .forPreviews,
//        registry: Registry(),
//        profileObservable: .forPreviews,
//        errorHandler: .default()
//    )
//    .task {
//        try? WebReceiverManager.forPreviews.start()
//    }
//}
