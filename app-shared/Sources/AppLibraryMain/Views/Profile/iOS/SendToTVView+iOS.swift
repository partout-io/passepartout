// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import CommonLibrary
import CommonResources
import SwiftUI

struct SendToTVView: View {

    @Environment(\.appConfiguration)
    private var appConfiguration

    @Binding
    var isPresented: Bool

    let onComplete: (URL, String) async throws -> Void

    @State
    private var isSending = false

    @State
    private var path = NavigationPath()

    var body: some View {
        qrScanView
            .navigationDestination(for: NavigationRoute.self, destination: pushDestination)
            .themeNavigationStack(
                closable: true,
                onClose: {
                    isPresented = false
                },
                path: $path
            )
    }
}

private extension SendToTVView {
    enum NavigationRoute: Hashable {
        case enterPasscode(URL)
    }

    @ViewBuilder
    func pushDestination(for item: NavigationRoute) -> some View {
        switch item {
        case .enterPasscode(let url):
            passcodeView(url: url)
        }
    }
}

private extension SendToTVView {
    var qrScanView: some View {
        SendToTVQRScanView { error in
            if let error {
#if targetEnvironment(simulator)
//                path.append(NavigationRoute.enterPasscode(URL(string: "http://10.42.0.132:10000")!))
                path.append(NavigationRoute.enterPasscode(URL(string: "http://172.20.10.14:10000")!))
#else
                pp_log_g(.App.core, .error, "Unable to open QR scanner: \(error)")
                isPresented = false
#endif
            }
        } onDetect: { url in
            path.append(NavigationRoute.enterPasscode(url))
        }
        .themeNavigationDetail()
        .navigationTitle(Strings.Views.Profile.SendTv.title_compound)
    }

    func passcodeView(url: URL) -> some View {
        SendToTVPasscodeView(length: appConfiguration.constants.webReceiver.passcodeLength) { passcode in
            do {
                isSending = true
                try await onComplete(url, passcode)
                isSending = false
            } catch {
                isSending = false
                throw error
            }
        }
        .disabled(isSending)
        .themeNavigationDetail()
        .navigationTitle(Strings.Global.Nouns.passcode)
    }
}

#Preview {
    SendToTVView(
        isPresented: .constant(true),
        onComplete: { _, _ in }
    )
    .withMockEnvironment()
}

#endif
