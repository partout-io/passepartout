// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension Dependencies {
    nonisolated func coreDataLogger() -> LoggerProtocol {
        CoreDataPersistentStoreLogger()
    }
}

private struct CoreDataPersistentStoreLogger: LoggerProtocol {
    func debug(_ msg: String) {
        pp_log_g(.App.core, .info, msg)
    }

    func warning(_ msg: String) {
        pp_log_g(.App.core, .error, msg)
    }
}
