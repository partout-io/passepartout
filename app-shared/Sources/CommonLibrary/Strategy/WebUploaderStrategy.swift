// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

public protocol WebUploaderStrategy: Sendable {
    func upload(_ form: MultipartForm, to url: URL) async throws
}
