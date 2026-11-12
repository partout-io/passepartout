// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Waits for the in-flight operation, skipping superseded pending requests.
@MainActor
public final class SingleAsyncRequest {
    private var pending: Task<Void, Never>?

    public init() {}

    deinit {
        pending?.cancel()
    }

    @discardableResult
    public func submit(
        operation: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        let previous = pending
        previous?.cancel()
        let task = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            await operation()
        }
        pending = task
        return task
    }
}
