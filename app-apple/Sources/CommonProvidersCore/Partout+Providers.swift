// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension LoggerCategory {
    public static let providers = LoggerCategory(rawValue: "providers")
}

public enum PartoutProviderError: Error {
    /// A provider module is corrupt.
    case corruptModule(_ error: Error)

    /// A provider was chosen but the target entity is missing.
    case missingEntity

    /// A provider was chosen but a required option is missing.
    case missingOption(_ option: String? = nil)
}
