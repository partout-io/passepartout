// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import SwiftUI

extension URL {
    public init?(httpAddress: String, port: Int) {
        self.init(string: "http://\(httpAddress):\(port)")
    }

    public var filename: String {
        deletingPathExtension()
            .lastPathComponent
    }

    public func open() {
#if os(iOS)
        UIApplication.shared.open(self)
#elseif os(macOS)
        NSWorkspace.shared.open(self)
#else
        fatalError("Unsupported")
#endif
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
