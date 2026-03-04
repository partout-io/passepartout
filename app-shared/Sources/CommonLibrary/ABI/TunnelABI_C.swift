// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !os(iOS) && !os(tvOS)
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var globalABI: TunnelABIProtocol?

// WARNING: Tasks must be .detached because MainActor is blocked

@_cdecl("psp_tunnel_start")
@MainActor
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
    let jniWrapper = args.pointee.jni_wrapper
    // Start tunnel ABI (synchronously)
    let semaphore = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var startError: Error?
    do {
        let abi = try TunnelABI.forCrossPlatform(
            appBundleData: appBundleData,
            appConstantsData: appConstantsData,
            preferencesData: preferencesData,
            profileInput: profileInput,
            cachesURL: cachesURL,
            jniWrapper: jniWrapper
        )
        Task.detached { @Sendable in
            defer { semaphore.signal() }
            do {
                try await abi.start(isInteractive: isInteractive)
            } catch {
                startError = error
            }
        }
        semaphore.wait()
        if let startError { throw startError }
        globalABI = abi
        callback?(0, nil)
    } catch {
        callback?(-1, error.localizedDescription)
        fatalError("Unable to start tunnel: \(error)")
    }
    // Block main thread indefinitely if daemon
    if isDaemon { semaphore.wait() }
}

@_cdecl("psp_tunnel_stop")
@MainActor
public func __psp_tunnel_stop(callback: (@convention(c) () -> Void)?) {
    Task.detached {
        await globalABI?.stop()
        globalABI = nil
        callback?()
    }
}
#endif
