// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(iOS)

import SwiftUI

public struct PasscodeInputView: UIViewRepresentable {
    private let length: Int

    private let onEnter: (String) async throws -> Void

    @State
    private var passcode = ""

    public init(length: Int, onEnter: @escaping (String) async throws -> Void) {
        self.length = length
        self.onEnter = onEnter
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .fill
        stack.distribution = .fillEqually
        context.coordinator.setupTextFields(in: stack, count: length)
        context.coordinator.textFields.first?.becomeFirstResponder()
        return stack
    }

    public func updateUIView(_ uiView: UIStackView, context: Context) {
        for (i, tf) in context.coordinator.textFields.enumerated() {
            let char: String = {
                let index = passcode.index(
                    passcode.startIndex,
                    offsetBy: i,
                    limitedBy: passcode.endIndex
                )
                guard let index, index < passcode.endIndex else {
                    return ""
                }
                return String(passcode[index])
            }()
            guard tf.text != char else { continue }
            tf.text = char
        }
    }
}

extension PasscodeInputView {

    @MainActor
    public final class Coordinator: NSObject, UITextFieldDelegate {
        private let parent: PasscodeInputView

        fileprivate private(set) var textFields: [PasscodeTextField] = []

        init(_ parent: PasscodeInputView) {
            self.parent = parent
        }

        func setupTextFields(in stackView: UIStackView, count: Int) {
            textFields = []

            for i in 0..<count {
                let tf = PasscodeTextField()
                tf.delegate = self
                tf.onBackspace = { [weak self] in
                    guard let self else { return }
                    if i > 0 {
                        textFields[i - 1].becomeFirstResponder()
                    }
                    updatePasscode()
                }
                tf.textAlignment = .center
                tf.keyboardType = .numberPad
                tf.font = .preferredFont(forTextStyle: .title1)
                tf.layer.borderWidth = 1
                tf.layer.cornerRadius = 6
                tf.layer.borderColor = UIColor.gray.cgColor
                tf.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
                tf.tag = i
                tf.translatesAutoresizingMaskIntoConstraints = false

                textFields.append(tf)
                stackView.addArrangedSubview(tf)
            }
        }

        func updatePasscode() {
            let newPasscode = textFields.map { $0.text ?? "" }.joined()
            parent.passcode = newPasscode
        }

        func submitPasscode() {
            Task {
                do {
                    try await parent.onEnter(parent.passcode)
                } catch {
                    parent.passcode = ""
                    textFields.forEach { $0.text = nil }
                    try await Task.sleep(for: .milliseconds(200))
                    textFields.first?.becomeFirstResponder()
                }
            }
        }

        @objc
        func textFieldDidChange(_ textField: UITextField) {
            let idx = textField.tag

            // truncate to 1 digit
            if let text = textField.text, text.count > 1 {
                let first = String(text.prefix(1))
                textField.text = first
            }

            // non-empty input?
            if let text = textField.text, !text.isEmpty {

                // submit passcode on last digit
                if idx == textFields.count - 1 {
                    submitPasscode()
                }
                // move to next digit otherwise
                else if idx < textFields.count - 1 {
                    textFields[idx + 1].becomeFirstResponder()
                }
            }

            updatePasscode()
        }

        public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

            // only allow editing of first non-empty
            for (i, tf) in textFields.enumerated() where textField === tf {
                let notEmptyBefore = textFields
                    .prefix(i)
                    .allSatisfy {
                        $0.text?.isEmpty != true
                    }
                guard notEmptyBefore else {
                    return false
                }
            }
            return true
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            textField.selectAll(nil)
        }

        // only allow digits
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        }
    }
}

private final class PasscodeTextField: UITextField {
    var onBackspace: (() -> Void)?

    override func deleteBackward() {
        super.deleteBackward()
        onBackspace?()
    }
}

#Preview {
    PasscodeInputView(length: 4) { _ in }
        .frame(height: 100)
}

#endif
