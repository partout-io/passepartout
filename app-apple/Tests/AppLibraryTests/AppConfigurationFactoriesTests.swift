// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppResources
@testable import CommonLibrary
import Foundation
import Partout
import Testing

struct AppConfigurationFactoriesTests {
    @Test
    func developerIDTunnelDefaultsUseStandardDomainWithoutAppGroup() {
        let key = "AppConfigurationFactoriesTests.\(UUID().uuidString)"
        let expected = "standard"
        UserDefaults.standard.set(expected, forKey: key)
        defer {
            UserDefaults.standard.removeObject(forKey: key)
        }

        let sut = appConfiguration(distributionTarget: .developerID)

        #expect(sut.makeTunnelDefaults().string(forKey: key) == expected)
    }

    @Test
    func appStoreTunnelDefaultsUseAppGroupDomain() throws {
        let suiteName = "AppConfigurationFactoriesTests.\(UUID().uuidString)"
        let key = "value"
        let expected = "group"
        let groupDefaults = try #require(UserDefaults(suiteName: suiteName))
        groupDefaults.set(expected, forKey: key)
        defer {
            groupDefaults.removePersistentDomain(forName: suiteName)
        }
        let sut = appConfiguration(
            distributionTarget: .appStore,
            bundleStrings: [
                ABI.AppBundle.BundleKey.groupId.rawValue: suiteName
            ]
        )

        #expect(sut.makeTunnelDefaults().string(forKey: key) == expected)
    }

    @Test
    func coderMatchesDistributionTarget() {
        let appStore = appConfiguration(
            distributionTarget: .appStore,
            bundleStrings: [
                ABI.AppBundle.BundleKey.keychainGroupId.rawValue: "group.example.keychain",
                ABI.AppBundle.BundleKey.tunnelId.rawValue: "com.example.PacketTunnel"
            ]
        )
        let developerID = appConfiguration(
            distributionTarget: .developerID,
            bundleStrings: [
                ABI.AppBundle.BundleKey.tunnelId.rawValue: "com.example.PacketTunnel"
            ]
        )
        let coder = CodingRegistry(registry: Registry(withKnown: true))

        let appStorePair = appStore.makeKeychainAndNECoder(
            .global,
            bundleIdentifier: "com.example.App",
            coder: coder
        )
        let developerIDPair = developerID.makeKeychainAndNECoder(
            .global,
            bundleIdentifier: "com.example.App",
            coder: coder
        )

        #expect(appStorePair.neCoder is KeychainNEProtocolCoder)
        #expect(developerIDPair.neCoder is ProviderNEProtocolCoder)
    }

    @Test
    func developerIDCoderSavesTaggedProfileInProviderConfiguration() throws {
        let sut = appConfiguration(
            distributionTarget: .developerID,
            bundleStrings: [
                ABI.AppBundle.BundleKey.tunnelId.rawValue: "com.example.PacketTunnel"
            ]
        )
        let coder = CodingRegistry(registry: Registry(withKnown: true))
        let codingPair = sut.makeKeychainAndNECoder(
            .global,
            bundleIdentifier: "com.example.App",
            coder: coder
        )
        let dns = try DNSModule.Builder(servers: ["1.1.1.1"]).build()
        let profile = try Profile.Builder(
            name: "Test",
            modules: [dns],
            activeModulesIds: [dns.id]
        ).build()

        let proto = try codingPair.neCoder.protocolConfiguration(from: profile)
        let json = try #require(
            proto.providerConfiguration?[ProviderNEProtocolCoder.profileKey] as? String
        )
        let tagged = try ABI.decodeJSON(TaggedProfile.self, from: json)

        #expect(tagged.id == profile.id)
        #expect(tagged.activeModulesIds == profile.activeModulesIds)
    }
}

private func appConfiguration(
    distributionTarget: ABI.DistributionTarget,
    bundleStrings: [String: String] = [:]
) -> ABI.AppConfiguration {
    ABI.AppConfiguration(
        bundle: ABI.AppBundle(
            distributionTarget: distributionTarget,
            displayName: "Test",
            versionNumber: "1.2.3",
            buildNumber: 123,
            bundleStrings: bundleStrings
        ),
        constants: Resources.constants
    )
}
