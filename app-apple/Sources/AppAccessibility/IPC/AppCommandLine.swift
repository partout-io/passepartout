// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public enum AppCommandLine {
    public enum Value: String {
        case fakeIAP = "-pp_fake_iap"

        case fakeMigration = "-pp_fake_migration"

        case withoutRateLimits = "-pp_without_rate_limits"

        case withReportIssue = "-pp_with_report_issue"

        case uiTesting = "-pp_ui_testing"
    }

    public static func contains(_ argument: Value) -> Bool {
        CommandLine.arguments.contains(argument.rawValue)
    }
}
