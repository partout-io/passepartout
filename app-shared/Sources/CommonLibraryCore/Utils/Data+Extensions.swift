// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Data {
    public func toTemporaryURL(withFilename filename: String) -> URL? {
        let path = FileManager.default.makeTemporaryPath(filename: filename)
        do {
            try write(toFile: path)
            return URL(fileURLWithPath: path)
        } catch {
            return nil
        }
    }
}
