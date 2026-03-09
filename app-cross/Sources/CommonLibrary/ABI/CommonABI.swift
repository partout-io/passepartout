// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
#if PSP_ABI
import CommonLibrary_C

@_cdecl("psp_partout_version")
public nonisolated func __psp_partout_version() -> UnsafePointer<CChar>! {
    PartoutConstants.cVersionIdentifier
}
#endif

// MARK: - Helpers

extension ABI {
    static func run(
        _ block: @escaping @Sendable @BusinessActor () async -> Void
    ) {
        Task { @Sendable @BusinessActor in
            await block()
        }
    }

    static func run(
        _ ctx: UnsafeMutableRawPointer?,
        _ block: @escaping @Sendable @BusinessActor (UnsafeMutableRawPointer?) async -> Void
    ) {
        nonisolated(unsafe) let unsafeCtx = ctx
        Task { @Sendable @BusinessActor in
            await block(unsafeCtx)
        }
    }
}

extension UnsafePointer where Pointee == CChar {
    var asJSONData: Data? {
        String(cString: self).data(using: .utf8)
    }
}
