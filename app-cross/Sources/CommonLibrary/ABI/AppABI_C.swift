// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var abi: AppABI?

@c(psp_app_init)
public func __psp_app_init(args: UnsafePointer<psp_app_init_args>?) {
    guard let args,
          let appBundleData = args.pointee.bundle?.asJSONData,
          let appConstantsData = args.pointee.constants?.asJSONData,
          let cProfilesDir = args.pointee.profiles_dir,
          let cCacheDir = args.pointee.cache_dir else {
        fatalError("NULL args or required fields")
    }
    let preferencesData = args.pointee.preferences?.asJSONData
    if args.pointee.preferences != nil {
        assert(preferencesData != nil, "Unable to decode preferences")
    }
    let eventContext = args.pointee.event_ctx
    let eventCallback = args.pointee.event_cb
    let eventHandler = ABI.EventHandler(
        context: eventContext,
        callback: { ctx, event in
            guard let eventCallback else { return }
            // Enrich event JSON with metadata for decoding
            let wrapper = ABI.EventWrapper(event)
            do {
                // Dispatch JSON event to cross-platform apps
                let json = try ABI.encodeWrapper(wrapper)
                json.withCString {
                    eventCallback(ctx, $0)
                }
            } catch {
                assertionFailure("Unable to encode event: \(event), \(error)")
            }
        }
    )
    let profilesDir = String(cString: cProfilesDir)
    let cachesURL = URL(filePath: String(cString: cCacheDir))
    ABI.run {
        do {
            abi = try AppABI.forCrossPlatform(
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profilesDir: profilesDir,
                cachesURL: cachesURL
            )
            abi?.registerEvents(eventHandler)
        } catch {
            fatalError("Unable to start app: \(error)")
        }
    }
}

@c(psp_app_deinit)
public func __psp_app_deinit() {
    abi = nil
}

@c(psp_app_on_foreground)
public func __psp_app_on_foreground() {
    ABI.run {
        abi?.onApplicationActive()
    }
}

@c(psp_app_import_profile_path)
public func __psp_app_import_profile_path(
    path: UnsafePointer<CChar>?,
    context: UnsafeMutableRawPointer?,
    completion: psp_abi_completion?
) {
    guard let abi, let path else { return }
    let swiftPath = String(cString: path)
    ABI.run(context) { ctx in
        do {
            try await abi.profile.importFile(swiftPath, passphrase: nil)
            completion?(ctx, 0, nil)
        } catch {
            completion?(ctx, -1, error.localizedDescription)
        }
    }
}

@c(psp_app_import_profile_text)
public func __psp_app_import_profile_text(
    text: UnsafePointer<CChar>?,
    filename: UnsafePointer<CChar>?,
    context: UnsafeMutableRawPointer?,
    completion: psp_abi_completion?
) {
    guard let abi, let text, let filename else { return }
    let swiftText = String(cString: text)
    let swiftFilename = String(cString: filename)
    ABI.run(context) { ctx in
        do {
            try await abi.profile.importText(swiftText, filename: swiftFilename, passphrase: nil)
            completion?(ctx, 0, nil)
        } catch {
            completion?(ctx, -1, error.localizedDescription)
        }
    }
}

@c(psp_app_flush_log)
public func __psp_app_flush_log() {
    pspLogFlush()
}

#endif
