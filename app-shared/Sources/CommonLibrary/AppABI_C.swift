// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)

import CommonLibraryCore_C
import PartoutABI_C

nonisolated(unsafe)
private var abi: AppABIProtocol?

@_cdecl("psp_app_init")
@MainActor
public func __psp_app_init(args: UnsafePointer<psp_app_init_args>?) {
    guard let args else { fatalError() }
//    args.pointee.event_cb
//    args.pointee.event_ctx
    var appConfiguration: ABI.AppConfiguration!// = args.pointee.app_configuration
    var kvStore: KeyValueStore!
    let profilesPath = args.pointee.profiles_dir.flatMap { String(cString: $0) }
//    abi = AppABI(
//        appConfiguration: appConfiguration,
//        kvStore: kvStore,
//        profilesPath: profilesPath
//    )
}

@_cdecl("psp_app_deinit")
@MainActor
public func __psp_app_deinit() {
    abi = nil
}

#endif
