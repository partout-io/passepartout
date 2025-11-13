// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension Utils {
    public static func copyToPasteboard(_ string: String) {
#if os(iOS)
        let pb: UIPasteboard = .general
        pb.string = string
#elseif os(macOS)
        let pb: NSPasteboard = .general
        pb.clearContents()
        pb.setString(string, forType: .string)
#else
        fatalError("Copy unavailable")
#endif
    }
}
