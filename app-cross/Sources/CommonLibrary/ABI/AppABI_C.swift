// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var abi: AppABI?

@_cdecl("psp_app_init")
public func __psp_app_init(args: UnsafePointer<psp_app_init_args>?) {
    guard let args,
          let appBundleData = args.pointee.bundle?.asJSONData,
          let appConstantsData = args.pointee.constants?.asJSONData,
          let cProfilesDir = args.pointee.profiles_dir,
          let cCacheDir = args.pointee.cache_dir else {
        fatalError("NULL args or required fields")
    }
    let preferencesData = args.pointee.preferences?.asJSONData
//    var kvStore: KeyValueStore!
    nonisolated(unsafe) let eventContext = args.pointee.event_ctx
    let eventCallback = args.pointee.event_cb
    let profilesDir = String(cString: cProfilesDir)
    let cachesURL = URL(filePath: String(cString: cCacheDir))
    abiDispatch {
        do {
            abi = try AppABI.forCrossPlatform(
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profilesDir: profilesDir,
                cachesURL: cachesURL,
                eventContext: eventContext,
                eventCallback: eventCallback
            )
            abi?.registerEvents(context: nil) { ctx, event in
                // FIXME: #1656, C ABI, dispatch events to UI
            }
        } catch {
            fatalError("Unable to start app: \(error)")
        }
    }
}

@_cdecl("psp_app_deinit")
public func __psp_app_deinit() {
    abi = nil
}

@_cdecl("psp_app_on_foreground")
public func __psp_app_on_foreground() {
    abiDispatch {
        abi?.onApplicationActive()
    }
}

@_cdecl("psp_app_import_profile")
public func __psp_app_import_profile(cPath: UnsafePointer<CChar>?) {
    guard let abi, let cPath else { return }
    let path = String(cString: cPath)
    abiDispatch {
        do {
            try await abi.profile.importFile(path, passphrase: nil)
        } catch {
            // FIXME: #1656, C ABI, return error via completion callback
        }
    }
}

@_cdecl("psp_app_flush_log")
public func __psp_app_flush_log() {
    pspLogFlush()
}

#endif
