// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum StoreResult: Sendable {
        case done
        case pending
        case notFound
        case cancelled
    }
}
