// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

enum DiagnosticsRoute: Hashable {
    case appLog(title: String)

    case profile(ABI.AppProfileHeader)

    case tunnelLog(title: String, url: URL?)
}
