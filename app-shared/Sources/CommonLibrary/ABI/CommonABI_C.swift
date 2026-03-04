// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)
import Partout

@_cdecl("psp_partout_version")
public nonisolated func __psp_partout_version() -> UnsafePointer<CChar>! {
    PartoutConstants.cVersionIdentifier
}
#endif

extension UnsafePointer where Pointee == CChar {
    var asJSONData: Data? {
        String(cString: self).data(using: .utf8)
    }
}
