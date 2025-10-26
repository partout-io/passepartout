// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)

import CommonLibrary
import CommonUtils
import SwiftUI

struct SendToTVView: View {

    @Binding
    var isPresented: Bool

    let onComplete: (URL, String) async throws -> Void

    @State
    private var addressPort: HTTPAddressPort = .forWebReceiver

    @State
    private var passcode = ""

    @State
    private var isSending = false

    @StateObject
    private var errorHandler: ErrorHandler = .default()

    var body: some View {
        formView
            .disabled(isSending)
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: cancelButton)
                ToolbarItem(placement: .confirmationAction, content: confirmButton)
            }
            .themeNavigationStack()
            .withErrorHandler(errorHandler)
    }
}

private extension SendToTVView {
    var formView: some View {
        SendToTVFormView(addressPort: $addressPort, passcode: $passcode)
    }

    func cancelButton() -> some View {
        Button(Strings.Global.Actions.cancel, role: .cancel) {
            isPresented = false
        }
    }

    func confirmButton() -> some View {
        Button(Strings.Global.Actions.send, action: performSend)
            .disabled(isSending)
    }
}

private extension SendToTVView {
    var canSend: Bool {
        addressPort.url != nil
    }

    func performSend() {
        guard let url = addressPort.url else {
            return
        }
        Task {
            do {
                isSending = true
                try await onComplete(url, passcode)
                isSending = false
            } catch {
                isSending = false
                errorHandler.handle(error)
            }
        }
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
