// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

/// Waits for the in-flight operation, skipping superseded requests and results.
@MainActor
public final class SingleAsyncRequest<Value: Sendable> {
    private var pending: Task<Value?, Never>?
    private var generation = 0

    public init() {}

    deinit {
        pending?.cancel()
    }

    @discardableResult
    public func submit(
        operation: @escaping @MainActor () async -> Value
    ) -> Task<Value?, Never> {
        guard !Task.isCancelled else { return Task { nil } }
        let previous = pending
        previous?.cancel()
        generation += 1
        let currentGeneration = generation
        let task = Task<Value?, Never> { [weak self] in
            defer {
                if self?.generation == currentGeneration {
                    self?.pending = nil
                }
            }
            // An in-flight operation may finish despite cancellation.
            _ = await previous?.value
            guard !Task.isCancelled else { return nil }
            let value = await operation()
            return Task.isCancelled ? nil : value
        }
        pending = task
        return task
    }

    public func fetch(_ operation: @escaping @MainActor () async -> Value) async -> Value? {
        guard !Task.isCancelled else { return nil }
        let task = submit(operation: operation)
        return await withTaskCancellationHandler {
            let value = await task.value
            return Task.isCancelled ? nil : value
        } onCancel: {
            task.cancel()
        }
    }
}
