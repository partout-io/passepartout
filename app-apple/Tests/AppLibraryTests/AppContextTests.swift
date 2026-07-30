// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
@testable import AppResources
@testable import CommonLibrary
import Foundation
import Testing

@MainActor
struct AppContextTests {
    @Test
    func givenInitialManagerState_whenCreatingContext_thenUpdatesObservables() async {
        let harness = Harness(
            skipsPurchases: true,
            isRemoteImportingEnabled: true
        )

        let didReceiveInitialState = await eventually {
            !harness.context.iapObservable.isEnabled &&
                harness.context.profileObservable.isRemoteImportingEnabled
        }

        #expect(!harness.iapManager.isEnabled)
        #expect(didReceiveInitialState)
    }

    @Test
    func givenIAPStatusEvent_whenChangingManager_thenUpdatesAllConsumers() async {
        let harness = Harness()

        harness.iapManager.isEnabled = false
        let didDisable = await eventually {
            !harness.context.iapObservable.isEnabled &&
                harness.preferences[\.skipsPurchases]
        }
        #expect(didDisable)

        harness.iapManager.isEnabled = true
        let didEnable = await eventually {
            harness.context.iapObservable.isEnabled &&
                !harness.preferences[\.skipsPurchases]
        }
        #expect(didEnable)
    }

    @Test
    func givenProfiles_whenApplicationBecomesActive_thenLoadsAndObservesProfiles() async throws {
        let initialProfile = try profile(withName: "Initial")
        let harness = Harness(profiles: [initialProfile])

        #expect(!harness.context.profileObservable.isReady)
        harness.context.onApplicationActive()

        let didLoadInitialProfile = await eventually {
            harness.context.profileObservable.isReady &&
                harness.context.profileObservable.header(withId: initialProfile.id)?.name == initialProfile.name
        }
        #expect(didLoadInitialProfile)

        let addedProfile = try profile(withName: "Added")
        try await harness.context.profileObservable.save(addedProfile)

        let didObserveAddedProfile = await eventually {
            harness.context.profileObservable.header(withId: addedProfile.id)?.name == addedProfile.name
        }
        #expect(didObserveAddedProfile)
    }

    @Test
    func givenWebUpload_whenReceivingProfile_thenImportsTVProfile() async throws {
        let receiver = TestWebReceiver()
        let harness = Harness(webReceiver: receiver)
        harness.context.onApplicationActive()

        let didBecomeReady = await eventually {
            harness.context.profileObservable.isReady
        }
        #expect(didBecomeReady)

        try harness.context.webReceiverObservable.start()
        let didStartReceiver = await eventually {
            harness.context.webReceiverObservable.website?.url == receiver.url.absoluteString
        }
        #expect(didStartReceiver)

        let uploadedProfile = try profile(withName: "Uploaded")
        let contents = try harness.context.appEncoderObservable.json(fromProfile: uploadedProfile)
        receiver.receive(
            filename: harness.context.appEncoderObservable.defaultFilename(for: uploadedProfile),
            contents: contents
        )

        let didImportProfile = await eventually {
            guard let importedProfile = harness.context.profileObservable.profile(withId: uploadedProfile.id) else {
                return false
            }
            return importedProfile.attributes.isAvailableForTV == true
        }
        #expect(didImportProfile)
    }
}

@MainActor
private struct Harness {
    let context: AppContext
    let iapManager: IAPManager
    let preferences: AppPreferencesStore

    init(
        profiles: [Profile] = [],
        skipsPurchases: Bool = false,
        isRemoteImportingEnabled: Bool = false,
        webReceiver: any WebReceiver = DummyWebReceiver(url: URL(string: "http://127.0.0.1")!)
    ) {
        let appConfiguration = ABI.AppConfiguration(
            bundle: ABI.AppBundle(distributionTarget: .appStore),
            constants: Resources.constants
        )
        let registry = CodingRegistry(
            registry: Registry(withKnown: true)
        )
        let preferences = AppPreferencesStore()
        preferences.overwrite {
            $0.skipsPurchases = skipsPurchases
        }
        let iapManager = IAPManager()
        let profileManager = ProfileManager(profiles: profiles)
        profileManager.enableRemoteImporting(isRemoteImportingEnabled)

        let tunnel = Tunnel(
            .global,
            strategy: FakeTunnelStrategy(),
            environmentFactory: { @Sendable _ in
                SharedTunnelEnvironment(profileId: nil)
            }
        )
        let tunnelObservable = TunnelObservable(tunnel: tunnel)
        let webReceiverManager = WebReceiverManager(
            webReceiver: webReceiver,
            passcodeGenerator: { "123456" }
        )

        self.iapManager = iapManager
        self.preferences = preferences
        context = AppContext(
            apiManager: APIManager(),
            appConfiguration: appConfiguration,
            appEncoder: AppEncoder(coder: registry),
            configManager: ConfigManager(),
            defaults: UserDefaults(),
            extensionInstaller: nil,
            iapManager: iapManager,
            preferences: preferences,
            preferencesManager: PreferencesManager(),
            profileManager: profileManager,
            registry: registry,
            tunnelObservable: tunnelObservable,
            versionChecker: VersionChecker(),
            webReceiverManager: webReceiverManager
        )
    }
}

private final class TestWebReceiver: WebReceiver, @unchecked Sendable {
    let url = URL(string: "http://127.0.0.1:9000")!

    private let queue = DispatchQueue(label: "AppContextTests.TestWebReceiver")
    private var onReceive: (@Sendable (String, String) -> Void)?

    func start(
        passcode: String?,
        onReceive: @escaping @Sendable (String, String) -> Void
    ) throws -> URL {
        queue.sync {
            self.onReceive = onReceive
        }
        return url
    }

    func stop() {
    }

    func receive(filename: String, contents: String) {
        let receiver: (@Sendable (String, String) -> Void)? = queue.sync {
            self.onReceive
        }
        receiver?(filename, contents)
    }
}

@MainActor
private func profile(withName name: String) throws -> Profile {
    let dns = try DNSModule.Builder(servers: ["1.1.1.1"]).build()
    return try Profile.Builder(
        name: name,
        modules: [dns],
        activeModulesIds: [dns.id]
    ).build()
}

@MainActor
private func eventually(
    attempts: Int = 200,
    condition: @MainActor () -> Bool
) async -> Bool {
    for _ in 0..<attempts {
        if condition() {
            return true
        }
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}
