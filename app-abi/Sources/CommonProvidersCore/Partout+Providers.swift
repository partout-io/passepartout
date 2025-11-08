// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension LoggerCategory {
    public static let providers = Self(rawValue: "providers")
}

extension PartoutError.Code {
    public enum Providers {

        /// A provider module is corrupt.
        public static let corruptModule = PartoutError.Code("Providers.corruptModule")

        /// A provider was chosen but the target entity is missing.
        public static let missingEntity = PartoutError.Code("Providers.missingEntity")

        /// A provider was chosen but a required option is missing.
        public static let missingOption = PartoutError.Code("Providers.missingOption")
    }
}
