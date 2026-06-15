// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Array where Element == String {
    public var isLastEmpty: Bool {
        last?.trimmingCharacters(in: .whitespaces) == ""
    }
}

extension Collection {
    public var nilIfEmpty: [Element]? {
        !isEmpty ? Array(self) : nil
    }
}
