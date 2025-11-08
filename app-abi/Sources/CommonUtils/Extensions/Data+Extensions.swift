// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension Data {
    public func toTemporaryURL(withFilename filename: String) -> URL? {
        let path = NSTemporaryDirectory().appending(filename)
        let url = URL(fileURLWithPath: path)
        do {
            try write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
