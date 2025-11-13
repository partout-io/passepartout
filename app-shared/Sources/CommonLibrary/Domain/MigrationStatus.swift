// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public enum MigrationStatus: Equatable {
    case excluded
    case pending
    case done
    case failed
}
