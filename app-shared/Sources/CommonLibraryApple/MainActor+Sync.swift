// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// XXX: Trick to call MainActor code synchronously
extension MainActor {
    public static func sync<T>(_ block: @escaping @Sendable @MainActor () throws -> T) rethrows -> T where T: Sendable {
        guard Thread.isMainThread else {
            var result: T!
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                result = try block()
                semaphore.signal()
            }
            semaphore.wait()
            return result
        }
        return try MainActor.assumeIsolated(block)
    }
}
