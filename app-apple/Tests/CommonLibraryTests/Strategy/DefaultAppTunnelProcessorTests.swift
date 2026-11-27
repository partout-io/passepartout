// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import Partout
import Testing

@MainActor
struct DefaultAppTunnelProcessorTests {
    @Test(arguments: [OpenVPN.Credentials.OTPMethod.none, .append, .encode])
    func givenInteractiveLogin_whenConnecting_thenPersistsUpdatedProfile(method: OpenVPN.Credentials.OTPMethod) async throws {
        let original = try makeOpenVPNProfile(otp: nil, method: method)
        let repository = RecordingProfileRepository()
        let processor = makeProcessor(repository: repository)
        let tunnel = TunnelObservable(
            tunnel: PartoutTunnel(
                .global,
                strategy: FakeTunnelStrategy(delay: 0),
                environmentFactory: { @Sendable _ in SharedTunnelEnvironment(profileId: nil) }
            ),
            willInstall: processor.willInstall
        )
        let prepared = try original.withInteractiveLogin(username: "user", password: "123456", otp: "123456")
        let credentials = try #require((prepared.activeModules.first as? OpenVPNModule)?.credentials)
        #expect(credentials.password == (method == .none ? "123456" : "password"))
        #expect(credentials.otp == (method == .none ? nil : "123456"))
        #expect(credentials.otpMethod == method)
        try await tunnel.connect(to: prepared, force: true)
        #expect(await repository.persistedProfiles == [prepared])
        #expect(await repository.savedProfiles.isEmpty)
    }

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

    @Test
    func givenProfile_whenInstalling_thenPersistsWithoutSaving() async throws {
        let profile = try makeOpenVPNProfile(otp: nil)
        let repository = RecordingProfileRepository()
        let sut = makeProcessor(repository: repository)

        _ = try await sut.willInstall(
            profile,
            connect: true,
            force: true
        )

        #expect(await repository.persistedProfiles == [profile])
        #expect(await repository.savedProfiles.isEmpty)
    }
}

private extension DefaultAppTunnelProcessorTests {
    func makeProcessor(
        repository: ProfileRepository
    ) -> DefaultAppTunnelProcessor {
        DefaultAppTunnelProcessor(
            profileRepository: repository,
            extensionInstaller: nil
        )
    }

    func makeOpenVPNProfile(otp: String?, method: OpenVPN.Credentials.OTPMethod = .append) throws -> Profile {
        var configuration = OpenVPN.Configuration.Builder()
        configuration.ca = OpenVPN.CryptoContainer(pem: "ca")
        configuration.remotes = [
            try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.udp, 1194))
        ]
        let credentials = OpenVPN.Credentials.Builder(
            username: "user",
            password: "password",
            otpMethod: method,
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
}

private actor RecordingProfileRepository: ProfileRepository {
    private var profiles: [Profile] = []

    private var profilesContinuation: AsyncStream<[Profile]>.Continuation?

    private(set) var persistedProfiles: [Profile] = []

    private(set) var savedProfiles: [Profile] = []

    nonisolated var profilesPublisher: AsyncStream<[Profile]> {
        AsyncStream { continuation in
            Task {
                await setProfilesContinuation(continuation)
            }
        }
    }

    func fetchProfiles() -> [Profile] {
        profiles
    }

    func persistProfile(_ profile: Profile) {
        persistedProfiles.append(profile)
        upsert(profile)
    }

    func saveProfile(_ profile: Profile) {
        savedProfiles.append(profile)
        upsert(profile)
    }

    func removeProfiles(withIds profileIds: [Profile.ID]) {
        profiles.removeAll {
            profileIds.contains($0.id)
        }
        profilesContinuation?.yield(profiles)
    }

    func removeAllProfiles() {
        profiles = []
        profilesContinuation?.yield(profiles)
    }

    private func setProfilesContinuation(_ continuation: AsyncStream<[Profile]>.Continuation) {
        profilesContinuation = continuation
        continuation.yield(profiles)
    }

    private func upsert(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        profilesContinuation?.yield(profiles)
    }
}
