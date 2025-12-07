// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Data {
    public func toTemporaryURL(withFilename filename: String) -> URL? {
        let url = FileManager.default.makeTemporaryURL(filename: filename)
        do {
            try write(toFile: url.filePath())
            return url as? URL
        } catch {
            return nil
        }
    }
}
