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
    args: UnsafePointer<psp_tunnel_start_args>?
) -> Int32 {
    guard let args else {
        return PSPCompletionCodeArgs
    }
    nonisolated(unsafe) var bindings = args.pointee.bindings
    guard let appBundleData = args.pointee.bundle?.asJSONData,
          let appConstantsData = args.pointee.constants?.asJSONData,
          let cProfileJSON = args.pointee.profile,
          let cCacheDir = args.pointee.cache_dir else {
        bindings.free?(&bindings)
        return PSPCompletionCodeArgs
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
    // Start tunnel ABI
    let result = ABI.runBlockingInitialization {
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
            return PSPCompletionCodeOK
        } catch {
            if globalABI != nil {
                await globalABI?.stop()
                globalABI = nil
            } else {
                bindings.free?(&bindings)
            }
            return PSPCompletionCodeFailure
        }
    }
    if result == PSPCompletionCodeOK {
        pspLock(isDaemon: isDaemon)
    }
    return result
}

@c(psp_tunnel_stop)
public func __psp_tunnel_stop(completion: psp_completion) {
    ABI.run(completion) { callback in
        await globalABI?.stop()
        globalABI = nil
        callback?(PSPCompletionCodeOK, nil, nil)
    }
}

private func pspLock(isDaemon: Bool) {
    guard isDaemon else { return }
#if canImport(Darwin)
    CFRunLoopRun()
#else
    // Block main thread indefinitely to keep the process running
    let semaphore = DispatchSemaphore(value: 0)
    semaphore.wait()
#endif
}

#endif
