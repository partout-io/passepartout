// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_ABI
import CommonLibrary_C
import Partout

nonisolated(unsafe)
private var globalABI: TunnelABIProtocol?

@c(psp_tunnel_start)
public func __psp_tunnel_start(
    args: UnsafePointer<psp_tunnel_start_args>?,
    completion: psp_completion
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
    if args.pointee.preferences != nil {
        assert(preferencesData != nil, "Unable to decode preferences")
    }
    let profileInput: ABI.ProfileImporterInput = {
        let json = String(cString: cProfileJSON)
        // XXX: filename is ignored when importing a JSON profile
        return .contents(filename: "ThisIsIgnored", data: json)
    }()
    let cachesURL = URL(filePath: String(cString: cCacheDir))
    let isInteractive = args.pointee.is_interactive
    let isDaemon = args.pointee.is_daemon
    nonisolated(unsafe) let bindings = args.pointee.bindings
    // Start tunnel ABI
    ABI.run(completion) { callback in
        defer { pspUnlock() }
        do {
            await globalABI?.stop()
            globalABI = nil
            globalABI = try TunnelABI.forCrossPlatform(
                bindings: bindings,
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profileInput: profileInput,
                cachesURL: cachesURL
            )
            try await globalABI?.start(isInteractive: isInteractive)
            callback?(PSPCompletionCodeOK, nil)
        } catch {
            await globalABI?.stop()
            globalABI = nil
            callback?(PSPCompletionCodeFailure, error.localizedDescription)
            fatalError("Unable to start tunnel: \(error)")
        }
    }
    pspLock(isDaemon: isDaemon)
}

@c(psp_tunnel_stop)
public func __psp_tunnel_stop(completion: psp_completion) {
    ABI.run(completion) { callback in
        await globalABI?.stop()
        globalABI = nil
        callback?(PSPCompletionCodeOK, nil)
    }
}

private let semaphore = DispatchSemaphore(value: 0)

private func pspLock(isDaemon: Bool) {
#if canImport(Darwin)
    if isDaemon { CFRunLoopRun() }
#else
    // Wait for ABI to start
    semaphore.wait()
    // Block main thread indefinitely if daemon
    if isDaemon { semaphore.wait() }
#endif
}

private func pspUnlock() {
#if !canImport(Darwin)
    semaphore.signal()
#endif
}

#endif
