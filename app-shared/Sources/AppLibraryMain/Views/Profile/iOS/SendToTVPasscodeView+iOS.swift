// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

struct SendToTVPasscodeView: View {
    let length: Int

    let onEnter: (String) async throws -> Void

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        VStack {
            messageView
            passcodeView
                .frame(height: 80)
                .padding(.horizontal)
        }
        .withErrorHandler(errorHandler)
    }
}

private extension SendToTVPasscodeView {
    var messageView: some View {
        Text(Strings.Views.Profile.SendTv.Passcode.message)
    }

    var passcodeView: some View {
        PasscodeInputView(
            length: length,
            onEnter: {
                do {
                    try await onEnter($0)
                } catch {
                    errorHandler.handle(error)
                    throw error
                }
            }
        )
    }
}

#Preview {
    SendToTVPasscodeView(
        length: 4,
        onEnter: { _ in }
    )
}

#endif
