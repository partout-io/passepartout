// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

enum DiagnosticsRoute: Hashable {
    case appLog(title: String)

    case profile(profile: Profile)

    case tunnelLog(title: String, url: URL?)
}
