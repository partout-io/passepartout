// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Observation

@MainActor @Observable
public final class AppFormatter {
    private let dateFormatter: DateFormatter

    public init(constants: ABI.Constants) {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = constants.formats.timestamp
    }

    public nonisolated func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
