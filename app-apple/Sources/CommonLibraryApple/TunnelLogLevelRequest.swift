// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Provider messages cannot be recalled. Drain an in-flight change before applying the latest one.
@MainActor
final class TunnelLogLevelRequest {
    private var pending: Task<Void, Never>?

    deinit {
        pending?.cancel()
    }

    @discardableResult
    func submit(
        _ level: DebugLog.Level,
        operation: @escaping @MainActor (DebugLog.Level) async -> Void
    ) -> Task<Void, Never> {
        let previous = pending
        previous?.cancel()
        let task = Task {
            await previous?.value
            guard !Task.isCancelled else { return }
            await operation(level)
        }
        pending = task
        return task
    }
}
