// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Foundation
import Testing

struct ExtendedTunnelTests {
    private let ctx: PartoutLoggerContext = .global

    private func newStrategy() -> TunnelObservableStrategy {
        FakeTunnelStrategy(delay: 100)
    }
}

@MainActor
extension ExtendedTunnelTests {

    @Test
    func givenTunnel_whenDisconnectWithError_thenPublishesLastErrorCode() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { _ in
            env
        }
        let sut = ExtendedTunnel(tunnel: tunnel, interval: 0.1)

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()
        try await sut.connect(with: profile)
        env.setEnvironmentValue(.crypto, forKey: TunnelEnvironmentKeys.lastErrorCode)

        let exp = Expectation()
        var didCall = false
        Task {
            for await event in sut.didChange.subscribe() {
                if !didCall, sut.lastErrorCode(ofProfileId: profile.id) != nil {
                    didCall = true
                    await exp.fulfill()
                }
            }
        }

        try await tunnel.disconnect(from: profile.id)
        try await exp.fulfillment(timeout: 500)
        #expect(sut.lastErrorCode(ofProfileId: profile.id) == .crypto)
    }

    @Test
    func givenTunnel_whenPublishesDataCount_thenIsAvailable() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { _ in
            env
        }
        let sut = ExtendedTunnel(tunnel: tunnel, interval: 0.1)
        let stream = sut.activeProfilesStream
        let expectedDataCount = DataCount(500, 700)

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        #expect(await stream.nextElement() == [:])
        let active = await stream.nextElement()

        #expect(active?.first?.key == profile.id)
        env.setEnvironmentValue(expectedDataCount, forKey: TunnelEnvironmentKeys.dataCount)
        #expect(sut.dataCount(ofProfileId: profile.id) == expectedDataCount)
    }

    @Test
    func givenTunnelAndProcessor_whenInstall_thenProcessesProfile() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { _ in
            env
        }
        let processor = MockTunnelProcessor()
        let sut = ExtendedTunnel(tunnel: tunnel, processor: processor, interval: 0.1)
        let stream = sut.activeProfilesStream

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        #expect(await stream.nextElement() == [:])
        let active = await stream.nextElement()

        #expect(active?.first?.key == profile.id)
//        #expect(processor.titleCount == 1) // unused by FakeTunnelStrategy
        #expect(processor.willInstallCount == 1)
    }

    @Test
    func givenTunnel_whenStatusChanges_thenConnectionStatusIsExpected() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { _ in
            env
        }
        let processor = MockTunnelProcessor()
        let sut = ExtendedTunnel(tunnel: tunnel, processor: processor, interval: 0.1)
        let stream = sut.activeProfilesStream

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        #expect(await stream.nextElement() == [:])
        let pulled = await stream.nextElement()

        #expect(pulled?.first?.key == profile.id)
//        #expect(processor.titleCount == 1) // unused by FakeTunnelStrategy
        #expect(processor.willInstallCount == 1)
    }

    @Test
    func givenTunnelStatus_thenConnectionStatusIsExpected() async throws {
        let allTunnelStatuses: [TunnelStatus] = [
            .inactive,
            .activating,
            .active,
            .deactivating
        ]
        let allConnectionStatuses: [ConnectionStatus] = [
            .disconnected,
            .connecting,
            .connected,
            .disconnecting
        ]

        let env = SharedTunnelEnvironment(profileId: nil)
        let key = TunnelEnvironmentKeys.connectionStatus

        // no connection status, tunnel status unaffected
        allTunnelStatuses.forEach {
            #expect($0.withEnvironment(env) == $0)
        }

        // has connection status

        // affected if .active
        let tunnelActive: TunnelStatus = .active
        env.setEnvironmentValue(ConnectionStatus.connected, forKey: key)
        #expect(tunnelActive.withEnvironment(env) == .active)
        allConnectionStatuses
            .forEach {
                env.setEnvironmentValue($0, forKey: key)
                let statusWithEnv = tunnelActive.withEnvironment(env)
                switch $0 {
                case .connecting:
                    #expect(statusWithEnv == .activating)
                case .connected:
                    #expect(statusWithEnv == .active)
                case .disconnecting:
                    #expect(statusWithEnv == .deactivating)
                case .disconnected:
                    #expect(statusWithEnv == .inactive)
                }
            }

        // unaffected otherwise
        allTunnelStatuses
            .filter {
                $0 != .active
            }
            .forEach {
                #expect($0.withEnvironment(env) == $0)
            }
    }
}
