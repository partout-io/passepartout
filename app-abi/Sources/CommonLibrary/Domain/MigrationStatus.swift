// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public enum MigrationStatus: Equatable {
    case excluded

    case pending

    case done

    case failed
}
