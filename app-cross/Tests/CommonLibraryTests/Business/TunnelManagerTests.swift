// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct TunnelManagerTests {
    private let ctx: PartoutLoggerContext = .global

    private func newStrategy() -> TunnelObservableStrategy {
        FakeTunnelStrategy(delay: 100)
    }
}

@BusinessActor
extension TunnelManagerTests {
    @Test
    func givenTunnel_whenDisconnectWithError_thenPublishesLastErrorCode() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { @Sendable _ in
            env
        }
        let sut = TunnelManager(tunnel: tunnel, interval: 0.1)

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()
        try await sut.connect(with: profile)
        env.setEnvironmentValue(.crypto, forKey: TunnelEnvironmentKeys.lastErrorCode)

        let exp = Expectation()
        let stream = sut.observeObjects()
        var didCall = false
        Task {
            for await _ in stream {
                if !didCall, sut.lastError(ofProfileId: profile.id) != nil {
                    didCall = true
                    await exp.fulfill()
                }
            }
        }

        try await tunnel.disconnect(from: profile.id)
        try await exp.fulfillment(timeout: 500)
        let error = sut.lastError(ofProfileId: profile.id)
        switch error {
        case .partout(PartoutError(.crypto)):
            break
        default:
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func givenTunnel_whenPublishesDataCount_thenIsAvailable() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { @Sendable _ in
            env
        }
        let sut = TunnelManager(tunnel: tunnel, interval: 0.1)
        let stream = sut.observeObjects()
        #expect(await stream.nextActiveProfiles() == [:])

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.connect(with: profile)
        let active = await stream.nextActiveProfiles()

        let expectedXfer = ABI.ProfileTransfer(received: 500, sent: 700)
        #expect(active.first?.key == profile.id)
        let dataCount = DataCount(UInt(expectedXfer.received), UInt(expectedXfer.sent))
        env.setEnvironmentValue(dataCount, forKey: TunnelEnvironmentKeys.dataCount)
        try await Task.sleep(for: .milliseconds(200)) // > 0.1s to fetch environments
        let xfer = sut.transfer(ofProfileId: profile.id)
        #expect(xfer == expectedXfer)
    }

    @Test
    func givenTunnelAndProcessor_whenInstall_thenProcessesProfile() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { @Sendable _ in
            env
        }
        let processor = MockTunnelProcessor()
        let sut = TunnelManager(tunnel: tunnel, processor: processor, interval: 0.1)
        let stream = sut.observeObjects()
        #expect(await stream.nextActiveProfiles() == [:])

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        let active = await stream.nextActiveProfiles()

        #expect(active.first?.key == profile.id)
//        #expect(processor.titleCount == 1) // unused by FakeTunnelStrategy
        #expect(processor.willInstallCount == 1)
    }

    @Test
    func givenTunnel_whenStatusChanges_thenConnectionStatusIsExpected() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let tunnel = Tunnel(ctx, strategy: newStrategy()) { @Sendable _ in
            env
        }
        let processor = MockTunnelProcessor()
        let sut = TunnelManager(tunnel: tunnel, processor: processor, interval: 0.1)
        let stream = sut.observeObjects()
        #expect(await stream.nextActiveProfiles() == [:])

        let module = try DNSModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        let pulled = await stream.nextActiveProfiles()

        #expect(pulled.first?.key == profile.id)
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
        env.setEnvironmentValue(.connected, forKey: key)
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

private extension AsyncStream where Element == ABI.TunnelEvent {
    func nextActiveProfiles() async -> [Profile.ID: ABI.AppTunnelInfo] {
        for await event in self {
            if case .refresh(let payload) = event {
                return payload.active
            }
        }
        return [:]
    }
}
