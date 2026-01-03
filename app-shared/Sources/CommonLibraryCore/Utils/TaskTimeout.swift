// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct TaskTimeoutError: Error {
}

public func performTask<T>(withTimeout timeout: TimeInterval, taskBlock: @escaping @Sendable () async throws -> T) async throws -> T where T: Sendable {
    let task = Task {
        let taskResult = try await taskBlock()
        try Task.checkCancellation()
        return taskResult
    }
    let timeoutTask = Task {
        try await Task.sleep(for: .seconds(timeout))
        task.cancel()
    }
    do {
        let result = try await task.value
        timeoutTask.cancel()
        return result
    } catch {
        throw TaskTimeoutError()
    }
}
