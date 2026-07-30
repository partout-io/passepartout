// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
@preconcurrency import NetworkExtension
import Partout
// FIXME: ###, Move this import to TunnelLibrary
// import PartoutRuntime
import TunnelLibrary

final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private var abi: TunnelABIProtocol?
//    private var runtime: PartoutProviderRuntime?

    override func startTunnel(options: [String: NSObject]? = nil, completionHandler: @escaping @Sendable (Error?) -> Void) {
        let distributionTarget: ABI.DistributionTarget
#if PP_BUILD_MAC
        distributionTarget = .developerID
#else
        distributionTarget = .appStore
#endif
        let appConfiguration = Resources.newAppConfiguration(
            distributionTarget: distributionTarget,
            buildTarget: .tunnel
        )
        let logFormatter = appConfiguration.newLogFormatter()

        // Register essential logger ASAP because the profile context
        // can only be defined after decoding the profile. We would
        // in fact miss profile decoding errors. Re-register the
        // profile-aware context later.
        _ = pspLogRegister(
            for: .tunnelGlobal,
            with: appConfiguration,
            preferences: AppPreferencesStore(),
            localURL: appConfiguration.urlForTunnelLog,
            localMapper: logFormatter?.localMapper
        )
        pspLog(.core, .notice, "Partout \(PartoutConstants.version) (Swift)")

        // The app may propagate its local preferences on manual start
        let isInteractive = options?[TunnelObservable.Options.isManualKey] == true as NSNumber
        let startPreferences: ABI.AppPreferences? = {
            guard let encodedPreferences = options?[TunnelObservable.Options.appPreferences] as? Data else {
                return nil
            }
            do {
                return try ABI.decode(ABI.AppPreferences.self, from: encodedPreferences)
            } catch {
                pspLog(.core, .error, "Unable to decode startTunnel() preferences")
                return nil
            }
        }()

        // Update or fetch existing preferences
        let preferences = AppPreferencesStore({
            let persistedPreferences = UserDefaultsAppPreferences(defaults: .standard)
            if let startPreferences {
                persistedPreferences.copy(startPreferences)
                pspLog(.core, .debug, "PTP: persistedPreferences: \(persistedPreferences)")
                pspLog(.core, .debug, "PTP: startPreferences: \(startPreferences)")
                assert(persistedPreferences.serialized() == startPreferences)
                return startPreferences
            }
            return persistedPreferences
        }())

//        if preferences.isFlagEnabled(.zigRuntime) {
//            pspLog(.core, .info, "Using Zig runtime (\(PartoutProviderRuntime.version))")
//
//            let appGroup = appConfiguration.bundle.bundleString(for: .groupId)
//            guard let defaults = UserDefaults(suiteName: appGroup) else {
//                fatalError("No access to App Group: \(appGroup)")
//            }
//            // TODO: #218, cachesURL must be per-profile
//            let cachesURL = FileManager.default.temporaryDirectory
//            let registry = appConfiguration.newRegistryForTunnel(
//                preferences: preferences,
//                cachesURL: cachesURL
//            )
//            let decoder = appConfiguration.newNEProtocolCoder(.global, coder: registry)
//            do {
//                let runtime = try PartoutProviderRuntime(
//                    provider: self,
//                    decoder: decoder,
//                    options: .init(
//                        dnsFallbackServers: appConfiguration.constants.tunnel.dnsFallbackServers,
//                        logsSnapshots: false
//                    ),
//                    defaults: defaults,
//                    logsPrivateData: preferences[\.logsPrivateData],
//                    minDataCountDelta: appConfiguration.constants.tunnel.minDataCountDelta,
//                    logger: { level, message in
//                        guard let level = ABI.AppLogLevel(partoutCLevel: level),
//                              let message else { return }
//                        pspLog(.abi, level, String(cString: message))
//                    }
//                )
//                self.runtime = runtime
//
//                // Update the logger now that we have a context
//                _ = pspLogRegister(
//                    for: .tunnelProfile(runtime.profile.id),
//                    with: appConfiguration,
//                    preferences: preferences,
//                    localURL: appConfiguration.urlForTunnelLog,
//                    localMapper: logFormatter?.localMapper
//                )
//
//                Task { @MainActor in
//                    do {
//                        try await runtime.startTunnel()
//                        completionHandler(nil)
//                    } catch {
//                        pspLogFlush()
//                        completionHandler(error)
//                    }
//                }
//            } catch {
//                pspLogFlush()
//                completionHandler(error)
//            }
//            return
//        }

        // Defer to ABI
        pspLog(.core, .info, "Using Swift runtime")
        Task { @MainActor in
            do {
                // TODO: #218, cachesURL must be per-profile
                let cachesURL = FileManager.default.temporaryDirectory
                abi = try await TunnelABI.forNetworkExtension(
                    appConfiguration: appConfiguration,
                    preferences: preferences,
                    startPreferences: startPreferences,
                    cachesURL: cachesURL,
                    neProvider: self
                )
                abi?.log(.core, .notice, "Start PTP")
                try await abi?.start(isInteractive: isInteractive)
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
//        if let runtime {
//            await runtime.stopTunnel(with: reason)
//            pspLogFlush()
//            return
//        }
        guard let abi else { return }
        pspLog(.core, .notice, "Stop PTP, reason: \(String(describing: reason))")
        await abi.stop()
    }

    override func cancelTunnelWithError(_ error: Error?) {
//        if let runtime {
//            runtime.cancelTunnelWithError(error)
//            pspLogFlush()
//            super.cancelTunnelWithError(error)
//            return
//        }
        guard let abi else { return }
        pspLog(.core, .info, "Cancel PTP, error: \(String(describing: error))")
        abi.cancel(error)
        super.cancelTunnelWithError(error)
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
//        if let runtime {
//            return await runtime.handleAppMessage(messageData)
//        }
        guard let abi else { return nil }
        pspLog(.core, .debug, "Handle PTP message")
        return await abi.sendMessage(messageData)
    }

//    override func wake() {
//        if let runtime {
//            runtime.wake()
//            return
//        }
//    }
//
//    override func sleep() async {
//        if let runtime {
//            await runtime.sleep()
//            return
//        }
//    }
}
