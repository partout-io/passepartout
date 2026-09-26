// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Testing

@MainActor
struct AppCoordinatorRegressionTests {
    @Test(arguments: [ModuleType.Provider, .Undefined])
    func givenCustomModule_whenConnecting_thenAlertsOnlyForProviders(innerType: ModuleType) async throws {
        let custom = CustomModule(innerType: innerType, json: .object([
            "id": .string(UUID().uuidString),
            "providerId": .string("mullvad"),
            "providerModuleType": .string("WireGuard")
        ]))
        let encoded = try ABI.encodeJSON(TaggedProfile(
            id: UUID(), name: "Legacy", modules: [.Custom(custom)], activeModulesIds: []
        ))
        let profile = try AppImportExport.dummy.profile(fromString: encoded)
        let sut = RecordingCoordinator()

        await sut.onConnect(profile, force: false, verify: false)

        #expect(sut.messages.count == (innerType == .Provider ? 1 : 0))
    }
}

@MainActor
private final class RecordingCoordinator: AppCoordinatorConforming {
    let iapObservable = IAPObservable(iapManager: IAPManager(), supportsIAP: false)
    let tunnel = TunnelObservable(tunnel: PartoutTunnel(
        .global,
        strategy: FakeTunnelStrategy(delay: 0),
        environmentFactory: { _ in SharedTunnelEnvironment(profileId: nil) }
    ))
    var messages: [String] = []

    func onInteractiveLogin(_ profile: Profile, _ onComplete: @escaping InteractiveObservable.CompletionBlock) {}
    func onPurchaseRequired(for profile: Profile, features: Set<ABI.AppFeature>, continuation: (() -> Void)?) {}
    func onInfo(title: String, message: String) { messages.append(message) }
    func onError(_ error: Error, title: String) {}
}
