// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(tvOS)

import SwiftUI

public struct ThemeTextInputView: View {
    private let title: String

    private let message: String?

    private let monospaced: Bool

    @Binding
    private var isPresented: Bool

    private let onValidate: ((String) -> Bool)?

    private let onSubmit: (String) -> Void

    @State
    private var text = ""

    @FocusState
    private var isFocused: Bool

    public init(
        _ title: String,
        message: String? = nil,
        monospaced: Bool = false,
        isPresented: Binding<Bool>,
        onValidate: (@MainActor (String) -> Bool)? = nil,
        onSubmit: @escaping @MainActor (String) -> Void
    ) {
        self.title = title
        self.message = message
        self.monospaced = monospaced
        _isPresented = isPresented
        self.onValidate = onValidate
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack {
            if let message {
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themeMultiLine(true)
                    .padding(.bottom)
            }
            TextEditor(text: $text)
                .monospaced(monospaced)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.Global.Nouns.ok) {
                    isPresented = false
                    onSubmit(text)
                }
                .disabled(onValidate?(text) == false)
            }
        }
        .padding()
        .themeForm()
        .navigationTitle(title)
        .themeNavigationDetail()
        .themeNavigationStack(closable: true)
    }
}

#Preview {
    struct Preview: View {
        @State
        private var isPresented = false

        var body: some View {
            Button("Present") {
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                ThemeTextInputView(
                    "Comment",
                    message: "Message",
                    isPresented: $isPresented,
                    onValidate: { $0.count >= 10 },
                    onSubmit: { _ in }
                )
            }
        }
    }

    return Preview()
        .withMockEnvironment()
}

#endif
