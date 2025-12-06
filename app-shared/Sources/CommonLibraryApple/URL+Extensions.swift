// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension URL {
    public var filename: String {
        deletingPathExtension()
            .lastPathComponent
    }

    public static func mailto(to: String, subject: String, body: String) -> URL? {
        guard let escapedSubject = subject.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }
        guard let escapedBody = body.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
            return nil
        }
        return URL(string: "mailto:\(to)?subject=\(escapedSubject)&body=\(escapedBody)")
    }
}
