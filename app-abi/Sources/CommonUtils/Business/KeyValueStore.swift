// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol KeyValueStore {
    func value<V>(for key: String) -> V?

    mutating func set<V>(_ value: V?, for key: String)

    mutating func removeValue(for key: String)
}
