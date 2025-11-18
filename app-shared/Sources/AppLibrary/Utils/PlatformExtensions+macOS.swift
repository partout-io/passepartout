// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

#if os(macOS)

public enum EditMode {
    case inactive

    case active

    case transient
}

private struct EditModeEnvironmentKey: EnvironmentKey {
    public static var defaultValue: Binding<EditMode>? {
        nil
    }
}

extension EnvironmentValues {
    public var editMode: Binding<EditMode>? {
        get {
            self[EditModeEnvironmentKey.self]
        }
        set {
            self[EditModeEnvironmentKey.self] = newValue
        }
    }
}

extension View {
    public func cursor(_ cursor: CursorType) -> some View {
        onHover {
            if $0 {
                cursor.nsCursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension CursorType {
    var nsCursor: NSCursor {
        switch self {
        case .hand:
            return .pointingHand
        }
    }
}

#endif
