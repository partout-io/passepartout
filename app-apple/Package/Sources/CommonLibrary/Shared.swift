// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import PartoutInterfaces

extension LoggerCategory {
    public static let app = LoggerCategory(rawValue: "app")

    public enum App {
        public static let iap = LoggerCategory(rawValue: "app.iap")

        public static let migration = LoggerCategory(rawValue: "app.migration")

        public static let profiles = LoggerCategory(rawValue: "app.profiles")

        public static let web = LoggerCategory(rawValue: "app.web")
    }
}

extension Constants {
    public static let shared = Bundle.module.unsafeDecode(Constants.self, filename: "Constants")
}
