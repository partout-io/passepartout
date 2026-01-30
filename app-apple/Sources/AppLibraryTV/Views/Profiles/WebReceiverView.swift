// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

struct WebReceiverView: View {
    let webReceiverObservable: WebReceiverObservable

    let profileObservable: ProfileObservable

    let errorHandler: ErrorHandler

    var body: some View {
        VStack {
            if let website = webReceiverObservable.website {
                view(forWebsite: website)
            } else {
                Text(Strings.Views.Tv.WebReceiver.toggle)
            }
        }
        .task(handleUploadFailure)
        .onDisappear {
            webReceiverObservable.stop()
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
    func handleUploadFailure() async {
        for await error in webReceiverObservable.uploadFailure.subscribe() {
            errorHandler.handle(error)
        }
    }
}

// MARK: -

#Preview {
    WebReceiverView(
        webReceiverObservable: .forPreviews,
        profileObservable: .forPreviews,
        errorHandler: .default()
    )
    .task {
        try? WebReceiverObservable.forPreviews.start()
    }
}
