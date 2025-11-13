// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension LoggerCategory {
    public enum App {
        public static let core = LoggerCategory(rawValue: "app.core")

        public static let iap = LoggerCategory(rawValue: "app.iap")

        public static let migration = LoggerCategory(rawValue: "app.migration")

        public static let profiles = LoggerCategory(rawValue: "app.profiles")

        public static let web = LoggerCategory(rawValue: "app.web")
    }
}
