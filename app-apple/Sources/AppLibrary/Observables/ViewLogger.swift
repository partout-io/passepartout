// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Observation

@MainActor @Observable
public final class ViewLogger: AppLogger {
    private let abi: ABIProtocol

    public init(abi: ABIProtocol) {
        self.abi = abi
    }

    public func log(_ category: ABI.AppLogCategory, _ level: ABI.AppLogLevel, _ message: String) {
        abi.log(category, level, message)
    }

    public func formattedLog(timestamp: Date, message: String) -> String {
        abi.formattedLog(timestamp: timestamp, message: message)
    }
}
