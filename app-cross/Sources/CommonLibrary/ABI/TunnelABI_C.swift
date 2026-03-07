// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var globalABI: TunnelABIProtocol?

@_cdecl("psp_tunnel_start")
public func __psp_tunnel_start(
    args: UnsafePointer<psp_tunnel_start_args>?,
    callback: (@convention(c) (Int, UnsafePointer<CChar>?) -> Void)?
) {
    guard let args,
          let appBundleData = args.pointee.bundle?.asJSONData,
          let appConstantsData = args.pointee.constants?.asJSONData,
          let cProfileJSON = args.pointee.profile,
          let cCacheDir = args.pointee.cache_dir else {
        fatalError("NULL args or required fields")
    }
    // Process input
    let preferencesData = args.pointee.preferences?.asJSONData
    let profileInput: ABI.ProfileImporterInput = {
        let json = String(cString: cProfileJSON)
        return .contents(filename: "FIXME", data: json)
    }()
    // FIXME: #1656, C ABI, filename is used if module, discarded if JSON profile
    let cachesURL = URL(filePath: String(cString: cCacheDir))
    let isInteractive = args.pointee.is_interactive
    let isDaemon = args.pointee.is_daemon
    nonisolated(unsafe) let jniWrapper = args.pointee.jni_wrapper
    // Start tunnel ABI (synchronously)
#if !canImport(Darwin)
    let semaphore = DispatchSemaphore(value: 0)
#endif
    Task { @Sendable @BusinessActor in
#if !canImport(Darwin)
        defer { semaphore.signal() }
#endif
        do {
            let abi = try TunnelABI.forCrossPlatform(
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profileInput: profileInput,
                cachesURL: cachesURL,
                jniWrapper: jniWrapper
            )
            try await abi.start(isInteractive: isInteractive)
            globalABI = abi
            callback?(0, nil)
        } catch {
            callback?(-1, error.localizedDescription)
            fatalError("Unable to start tunnel: \(error)")
        }
    }
#if canImport(Darwin)
    if isDaemon { CFRunLoopRun() }
#else
    // Wait for ABI to start
    semaphore.wait()
    // Block main thread indefinitely if daemon
    if isDaemon { semaphore.wait() }
#endif
}

@_cdecl("psp_tunnel_stop")
public func __psp_tunnel_stop(callback: (@convention(c) () -> Void)?) {
    Task { @Sendable @BusinessActor in
        await globalABI?.stop()
        globalABI = nil
        callback?()
    }
}
#endif
