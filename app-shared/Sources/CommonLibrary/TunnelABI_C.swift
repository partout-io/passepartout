// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)

import CommonLibraryCore_C

nonisolated(unsafe)
private var abi: TunnelABIProtocol? = nil

@_cdecl("psp_tunnel_start")
@MainActor
public func __psp_tunnel_start(args: UnsafePointer<psp_tunnel_start_args>?, callback: @escaping (Int) -> Void) {
//    guard let args else { fatalError() }
//    abi = TunnelABI.forCrossPlatform()
//    Task {
//        do {
//            try await abi?.start()
//            callback(0)
//        } catch {
//            callback(-1)
//        }
//    }
}

@_cdecl("psp_tunnel_stop")
@MainActor
public func __psp_tunnel_stop(callback: @escaping () -> Void) {
    Task {
        await abi?.stop()
        abi = nil
        callback()
    }
}

#endif
