// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding {
        lhs.wrappedValue ?? rhs
    } set: {
        lhs.wrappedValue = $0
    }
}

extension Binding where Value == Bool {
    public init<T: Equatable>(presenting other: Binding<T?>, equal value: T) {
        self.init {
            other.wrappedValue == value
        } set: {
            if !$0 {
                other.wrappedValue = nil
            }
        }
    }

    public init<T>(presenting other: Binding<T?>, if block: @escaping (T?) -> Bool) {
        self.init {
            block(other.wrappedValue)
        } set: {
            if !$0 {
                other.wrappedValue = nil
            }
        }
    }
}

extension Binding {
    public func toString() -> Binding<String> where Value == URL? {
        .init {
            wrappedValue?.absoluteString ?? ""
        } set: {
            wrappedValue = URL(string: $0) ?? wrappedValue
        }
    }

    public func toString(omittingZero: Bool = false) -> Binding<String> where Value: FixedWidthInteger {
        .init {
            if omittingZero, wrappedValue == .zero {
                return ""
            }
            return wrappedValue.description
        } set: {
            guard let v = Value($0) else {
                wrappedValue = .zero
                return
            }
            wrappedValue = v
        }
    }
}
