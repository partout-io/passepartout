// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

struct SendToTVQRScanView: View {
    let onLoad: (Error?) -> Void

    let onDetect: (URL) -> Void

    @State
    private var usingScanner = true

    @State
    private var addressPort: HTTPAddressPort = .forWebReceiver

    var body: some View {
        ZStack {
            videoView
            if usingScanner {
                overlayView
            } else {
                formView
            }
        }
    }
}

private extension SendToTVQRScanView {
    var videoView: some View {
        QRScanView(
            isAvailable: $usingScanner,
            onLoad: onLoad,
            onDetect: {
                guard let url = URL(string: $0) else {
                    return
                }
                onDetect(url)
            }
        )
    }

    var overlayView: some View {
        VStack {
            VStack(spacing: 20) {
                messageView
                enterManuallyButton
            }
            .padding(15)
            .background(.black.opacity(0.8))
            .cornerRadius(15)
            .padding()

            Spacer()
        }
    }

    var messageView: some View {
        Text(Strings.Views.Profile.SendTv.Qr.message(
            Strings.Global.Nouns.profiles,
            Strings.Views.Tv.Profiles.importLocal,
            Strings.Unlocalized.appleTV
        ))
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
    }

    var enterManuallyButton: some View {
        Button(Strings.Views.Profile.SendTv.Qr.Buttons.manual) {
            withAnimation {
                usingScanner = false
            }
        }
        .font(.headline)
    }

    var formView: some View {
        SendToTVFormView(addressPort: $addressPort)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Global.Nouns.ok) {
                        guard let url = addressPort.url else {
                            assertionFailure("Button should be disabled")
                            return
                        }
                        onDetect(url)
                    }
                    .disabled(addressPort.url == nil)
                }
            }
    }
}

// MARK: -

#Preview {
    SendToTVQRScanView(
        onLoad: { _ in },
        onDetect: { _ in }
    )
    .themeNavigationStack()
}

#endif
