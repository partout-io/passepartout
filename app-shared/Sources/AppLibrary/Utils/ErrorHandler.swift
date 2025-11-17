// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

// https://www.ralfebert.com/swiftui/generic-error-handling/

@MainActor @Observable
public final class ErrorHandler {
    let defaultTitle: String

    let dismissTitle: String

    let errorDescription: (Error) -> String

    private let beforeAlert: (String) -> Void

    fileprivate var currentAlert: ErrorAlert?

    fileprivate var isPresented = false

    var currentTitle: String {
        currentAlert?.title ?? defaultTitle
    }

    public init(
        defaultTitle: String,
        dismissTitle: String,
        errorDescription: @escaping (Error) -> String,
        beforeAlert: @escaping (String) -> Void
    ) {
        self.defaultTitle = defaultTitle
        self.dismissTitle = dismissTitle
        self.errorDescription = errorDescription
        self.beforeAlert = beforeAlert
    }

    public func handle(
        _ error: Error,
        title: String? = nil,
        message: String? = nil,
        messageSeparator: String = " ",
        onDismiss: (() -> Void)? = nil
    ) {
        let composedMessage = [message, errorDescription(error)]
            .compactMap { $0 }
            .joined(separator: messageSeparator)
        beforeAlert(composedMessage)

        currentAlert = ErrorAlert(
            title: title,
            message: composedMessage,
            dismissAction: onDismiss
        )
        enableLater {
            self.isPresented = $0
        }
    }

    public func handle(title: String, message: String, onDismiss: (() -> Void)? = nil) {
        currentAlert = ErrorAlert(
            title: title,
            message: message,
            dismissAction: onDismiss
        )
        enableLater {
            self.isPresented = $0
        }
    }
}

private struct ErrorAlert: Identifiable {
    let id = UUID()

    let title: String?

    let message: String

    let dismissAction: (() -> Void)?
}

// MARK: - Modifier

extension View {
    public func withErrorHandler(_ errorHandler: ErrorHandler) -> some View {
        modifier(HandleErrorsByShowingAlertViewModifier(
            errorHandler: errorHandler
        ))
    }
}

private struct HandleErrorsByShowingAlertViewModifier: ViewModifier {
    let errorHandler: ErrorHandler

    func body(content: Content) -> some View {
        content
            // Applying the alert for error handling using a background element
            // is a workaround, if the alert would be applied directly,
            // other .alert modifiers inside of content would not work anymore
            .background(
                EmptyView()
                    .alert(
                        errorHandler.currentTitle,
                        isPresented: errorHandler.binding(\.isPresented),
                        presenting: errorHandler.currentAlert
                     ) { alert in
                         Button(role: .cancel) {
                             alert.dismissAction?()
                         } label: {
                             Text(errorHandler.dismissTitle)
                         }
                     } message: { alert in
                         Text(alert.message.withTrailingDot)
                     }
            )
    }
}

private extension String {
    var withTrailingDot: String {
        guard !hasSuffix(".") && !hasSuffix("!") else {
            return self
        }
        return "\(self)."
    }
}
