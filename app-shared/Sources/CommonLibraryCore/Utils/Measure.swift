// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Dispatch

public func measureMillis(block: () throws -> Void, completion: (UInt64) -> Void) rethrows {
    let startDate = DispatchTime.now()
    try block()
    let endDate = DispatchTime.now()
    let elapsedNanos = endDate.uptimeNanoseconds - startDate.uptimeNanoseconds
    let elapsedMillis = UInt64(Double(elapsedNanos) / 1_000_000.0)
    completion(elapsedMillis)
}
