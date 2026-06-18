// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
@preconcurrency import NetworkExtension
import Partout

final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private var abi: TunnelABIProtocol?

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
        pspLog(.core, .notice, "Partout \(PartoutConstants.version)")

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

        // Defer to ABI
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
        guard let abi else { return }
        pspLog(.core, .notice, "Stop PTP, reason: \(String(describing: reason))")
        await abi.stop()
    }

    override func cancelTunnelWithError(_ error: Error?) {
        guard let abi else { return }
        pspLog(.core, .info, "Cancel PTP, error: \(String(describing: error))")
        abi.cancel(error)
        super.cancelTunnelWithError(error)
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        guard let abi else { return nil }
        pspLog(.core, .debug, "Handle PTP message")
        return await abi.sendMessage(messageData)
    }

//    override func wake() {
//        fwd?.wake()
//    }
//
//    override func sleep() async {
//        await fwd?.sleep()
//    }
}
