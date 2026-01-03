// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

public typealias LogFormatterBlock = @Sendable (ABI.AppLogLine) -> String
