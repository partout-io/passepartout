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
    context: UnsafeMutableRawPointer?,
    completion: psp_abi_completion?
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
    nonisolated(unsafe) let statusContext = args.pointee.status_ctx
    let statusCallback = args.pointee.status_cb
    let onStatus: SimpleConnectionDaemon.StatusCallback = { profileId, status in
        guard let statusCallback else { return }
        let wrapper = ABI.OnConnectionStatus(
            profileId: profileId.uuidString,
            status: status
        )
        do {
            let json = try ABI.encodeWrapper(wrapper)
            json.withCString {
                statusCallback(statusContext, $0)
            }
        } catch {
            assertionFailure("Unable to encode status: \(status), \(error)")
        }
    }
    nonisolated(unsafe) let jniWrapper = args.pointee.jni_wrapper
    // Start tunnel ABI
    ABI.run(context) { ctx in
        defer { pspUnlock() }
        do {
            globalABI = try TunnelABI.forCrossPlatform(
                appBundleData: appBundleData,
                appConstantsData: appConstantsData,
                preferencesData: preferencesData,
                profileInput: profileInput,
                cachesURL: cachesURL,
                onStatus: onStatus,
                jniWrapper: jniWrapper
            )
            try await globalABI?.start(isInteractive: isInteractive)
            completion?(ctx, 0, nil)
        } catch {
            completion?(ctx, -1, error.localizedDescription)
            fatalError("Unable to start tunnel: \(error)")
        }
    }
    pspLock(isDaemon: isDaemon)
}

@c(psp_tunnel_stop)
public func __psp_tunnel_stop(
    context: UnsafeMutableRawPointer?,
    completion: psp_abi_completion?
) {
    ABI.run(context) { ctx in
        await globalABI?.stop()
        globalABI = nil
        completion?(ctx, 0, nil)
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
