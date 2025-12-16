// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Combine

@MainActor
public final class ObservableList<T>: ObservableObject where T: Equatable {
    private let contains: (T) -> Bool

    private let add: (T) -> Void

    private let remove: (T) -> Void

    public init() {
        contains = { _ in false }
        add = { _ in }
        remove = { _ in }
    }

    public init(
        contains: @escaping (T) -> Bool,
        add: @escaping (T) -> Void,
        remove: @escaping (T) -> Void
    ) {
        self.contains = contains
        self.add = add
        self.remove = remove
    }

    public func contains(_ value: T) -> Bool {
        contains(value)
    }

    public func add(_ value: T) {
        objectWillChange.send()
        add(value)
    }

    public func remove(_ value: T) {
        objectWillChange.send()
        remove(value)
    }
}
