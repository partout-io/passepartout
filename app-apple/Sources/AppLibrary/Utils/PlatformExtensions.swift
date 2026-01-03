// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public protocol EditableView {
    var editMode: EditMode { get }
}

extension EditableView {
    public var isEditing: Bool {
        editMode == .active
    }
}

extension EditMode {
    public mutating func toggle() {
        switch self {
        case .active:
            self = .inactive

        case .inactive:
            self = .active

        default:
            break
        }
    }
}

public enum CursorType {
    case hand
}
