// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppResources
import CommonLibrary
@preconcurrency import NetworkExtension
import Partout
import PartoutRuntime
import TunnelLibrary

extension NSObject: @retroactive @unchecked Sendable {}

final class PacketTunnelProvider: NEPacketTunnelProvider, @unchecked Sendable {
    private var context: TunnelContextProtocol?

    override func startTunnel(options: [String: NSObject]? = nil) async throws {
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
        let logFormatter = appConfiguration.makeLogFormatter()

        // Register essential logger ASAP because the profile context
        // can only be defined after decoding the profile. We would
        // in fact miss profile decoding errors. Re-register the
        // profile-aware context later.
        _ = pspLogRegister(
            for: .tunnelGlobal,
            with: appConfiguration,
            preferences: AppPreferencesStore(),
            localURL: appConfiguration.urlForTunnelLog,
            localMapper: logFormatter.localMapper
        )
        pspLog(.app, .notice, "Partout version: \(PartoutRuntime.version)")
        pspLog(.app, .notice, "Partout version (Swift): \(PartoutCore.version)")

        // The app may propagate its local preferences on manual start
        let isInteractive = options?[TunnelObservable.Options.isManualKey] == true as NSNumber
        let startPreferences: ABI.AppPreferences? = {
            guard let encodedPreferences = options?[TunnelObservable.Options.appPreferences] as? Data else {
                return nil
            }
            do {
                return try ABI.decode(ABI.AppPreferences.self, from: encodedPreferences)
            } catch {
                pspLog(.app, .error, "Unable to decode startTunnel() preferences")
                return nil
            }
        }()

        // Update or fetch existing preferences
        let preferences = AppPreferencesStore({
            let persistedPreferences = UserDefaultsAppPreferences(defaults: .standard)
            if let startPreferences {
                pspLog(.app, .debug, "PTP: Apply start preferences")
                persistedPreferences.copy(startPreferences)
                assert(persistedPreferences.serialized() == startPreferences)
                return startPreferences
            }
            pspLog(.app, .debug, "PTP: Use persisted preferences")
            return persistedPreferences
        }())

        // A new redacted session must not inherit sensitive buffered or persisted lines.
        if !preferences[\.logsPrivateData] {
            try PartoutLogger.default.resetLog()
        }

        // Create the tunnel context
        do {
            context = try await TunnelContext.forProduction(
                neProvider: self,
                appConfiguration: appConfiguration,
                preferences: preferences
            )
        } catch TunnelContext.RuntimeError.unsupportedProviders {
            //
        }
        context?.log(.app, .notice, "Start PTP")
        try await context?.start(isInteractive: isInteractive)
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {
        guard let context else { return }
        pspLog(.app, .notice, "Stop PTP, reason: \(String(describing: reason))")
        await context.stop()
    }

    override func cancelTunnelWithError(_ error: Error?) {
        guard let context else { return }
        pspLog(.app, .info, "Cancel PTP, error: \(String(describing: error))")
        context.cancel(error)
        super.cancelTunnelWithError(error)
    }

    override func handleAppMessage(_ messageData: Data) async -> Data? {
        guard let context else { return nil }
        let response = await context.sendMessage(messageData)
        if let response,
           let output = try? ABI.decode(Message.Output.self, from: response),
           case .logLevel(let level) = output {
            UserDefaultsAppPreferences(defaults: .standard).extensiveLogging = level == .debug
        }
        return response
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
