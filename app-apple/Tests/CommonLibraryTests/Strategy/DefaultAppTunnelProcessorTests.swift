// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import Partout
import Testing

@MainActor
struct DefaultAppTunnelProcessorTests {
    @Test
    func givenTransientOTP_whenConnecting_thenSavesProfile() async throws {
        let profile = try makeOpenVPNProfile(otp: "123456")
        let repository = InMemoryProfileRepository()
        let sut = makeProcessor(repository: repository)

        let result = try await sut.willInstall(
            profile,
            connect: true,
            force: true
        )

        #expect(result == profile)
        #expect(repository.profiles == [profile])
        let openVPN = try #require(repository.profiles.first?.activeModules.first as? OpenVPNModule)
        #expect(openVPN.credentials?.otp == "123456")
    }

    @Test
    func givenProviderHeuristic_whenConnecting_thenSavesSelectedServer() async throws {
        let oldServer = makeProviderServer(id: "old")
        let selectedServer = makeProviderServer(id: "selected")
        let preset = makeProviderPreset()
        let profile = try makeProviderProfile(
            server: oldServer,
            preset: preset
        )
        let repository = InMemoryProfileRepository()
        let apiManager = APIManager(
            from: [ProviderAPI(preset: preset, servers: [oldServer, selectedServer])],
            repository: InMemoryAPIRepository()
        )
        let sut = makeProcessor(
            repository: repository,
            apiManager: apiManager
        )

        let result = try await sut.willInstall(
            profile,
            connect: true,
            force: false
        )

        #expect(result?.activeProviderModule?.entity?.server.serverId == "selected")
        #expect(repository.profiles.first?.activeProviderModule?.entity?.server.serverId == "selected")
    }

    @Test
    func givenInstallWithoutConnect_thenSavesProfile() async throws {
        let profile = try makeOpenVPNProfile(otp: nil)
        let repository = InMemoryProfileRepository()
        let sut = makeProcessor(repository: repository)

        _ = try await sut.willInstall(
            profile,
            connect: false,
            force: false
        )

        #expect(repository.profiles == [profile])
    }
}

private extension DefaultAppTunnelProcessorTests {
    func makeProcessor(
        repository: ProfileRepository,
        apiManager: APIManager? = nil
    ) -> DefaultAppTunnelProcessor {
        DefaultAppTunnelProcessor(
            profileRepository: repository,
            apiManager: apiManager,
            resolver: IdentityResolver(),
            extensionInstaller: nil,
            providerServerSorter: { _, _ in }
        )
    }

    func makeOpenVPNProfile(otp: String?) throws -> Profile {
        var configuration = OpenVPN.Configuration.Builder()
        configuration.ca = OpenVPN.CryptoContainer(pem: "ca")
        configuration.remotes = [
            try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.udp, 1194))
        ]
        let credentials = OpenVPN.Credentials.Builder(
            username: "user",
            password: "password",
            otpMethod: .append,
            otp: otp
        ).build()
        let module = try OpenVPNModule.Builder(
            configurationBuilder: configuration,
            credentials: credentials,
            isInteractive: true
        ).build()
        return try Profile.Builder(
            modules: [module],
            activeModulesIds: [module.id]
        ).build()
    }

    func makeProviderProfile(
        server: ProviderServer,
        preset: ProviderPreset
    ) throws -> Profile {
        var moduleBuilder = ProviderModule.Builder(
            providerId: .test,
            providerModuleType: .OpenVPN
        )
        moduleBuilder.entity = ProviderEntity(
            server: server,
            preset: preset,
            heuristic: .sameCountry("IT")
        )
        let module = try moduleBuilder.build()
        return try Profile.Builder(
            modules: [module],
            activeModulesIds: [module.id]
        ).build()
    }

    func makeProviderServer(id: String) -> ProviderServer {
        ProviderServer(
            metadata: ProviderServer.Metadata(
                providerId: .test,
                categoryName: "default",
                countryCode: "IT",
                otherCountryCodes: nil,
                area: nil
            ),
            serverId: id,
            hostname: "\(id).example.com",
            ipAddresses: nil,
            supportedModuleTypes: [.OpenVPN],
            supportedPresetIds: ["default"]
        )
    }

    func makeProviderPreset() -> ProviderPreset {
        ProviderPreset(
            providerId: .test,
            presetId: "default",
            description: "Default",
            moduleType: .OpenVPN,
            templateData: Data()
        )
    }
}

private extension ProviderID {
    static let test = ProviderID(rawValue: "test")
}

private struct IdentityResolver: Resolver {
    func resolvedProfile(_ profile: Profile) throws -> Profile {
        profile
    }

    func resolvedModule(_ module: Module, in profile: Profile?) throws -> Module {
        module
    }
}

private struct ProviderAPI: APIMapper {
    let preset: ProviderPreset

    let servers: [ProviderServer]

    func index() async throws -> [Provider] {
        []
    }

    func authenticate(_ module: ProviderModule, on deviceId: String) async throws -> ProviderModule {
        module
    }

    func infrastructure(for module: ProviderModule, cache: ProviderCache?) async throws -> ProviderInfrastructure {
        ProviderInfrastructure(
            presets: [preset],
            servers: servers,
            cache: nil
        )
    }
}
