// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

public protocol URLFetcher: Sendable {
    func data(for url: URL, cached: Bool) async throws -> Data
}
