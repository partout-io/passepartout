// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@MainActor
final class TunnelLogRequest {
    private var pending: Task<[String], Never>?
    private var generation = 0

    func fetch(_ operation: @escaping @MainActor () async -> [String]) async -> [String] {
        guard !Task.isCancelled else { return [] }
        let previous = pending
        previous?.cancel()
        generation += 1
        let currentGeneration = generation
        let task = Task {
            // Provider messages cannot be recalled. Drain the previous message before sending another.
            _ = await previous?.value
            guard !Task.isCancelled else { return [String]() }
            let lines = await operation()
            return Task.isCancelled ? [] : lines
        }
        pending = task
        defer {
            if generation == currentGeneration {
                pending = nil
            }
        }
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
