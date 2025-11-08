// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

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
