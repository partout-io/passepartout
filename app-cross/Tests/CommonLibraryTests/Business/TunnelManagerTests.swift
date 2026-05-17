// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct TunnelManagerTests {
    private let ctx: PartoutLoggerContext = .global

    private func newTunnel(_ env: TunnelEnvironment, processor: AppTunnelProcessor? = nil) async throws -> Tunnel {
        let tunnel = Tunnel(
            ctx,
            strategy: FakeTunnelStrategy(delay: 100),
            updateInterval: 0.1,
            willInstall: processor?.willInstall(_:),
            environmentFactory: { @Sendable _ in
                env
            }
        )
        try await tunnel.prepare(purge: false)
        return tunnel
    }
}

@BusinessActor
extension TunnelManagerTests {
    @Test
    func givenTunnel_whenDisconnectWithError_thenPublishesLastErrorCode() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let sut = try await newTunnel(env)

        let module = IPModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()
        try await sut.connect(with: profile)
        env.setEnvironmentValue(.crypto, forKey: TunnelEnvironmentKeys.lastErrorCode)

        let exp = Expectation()
        let stream = sut.snapshotsStream
        var didCall = false
        Task {
            for await _ in stream {
                if !didCall, sut.snapshots[profile.id]?.environment?.lastErrorCode != nil {
                    didCall = true
                    await exp.fulfill()
                }
            }
        }

        try await sut.disconnect(from: profile.id)
        try await exp.fulfillment(timeout: 500)
        let error = sut.snapshots[profile.id]?.environment?.lastErrorCode
        switch error {
        case .crypto:
            break
        default:
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    @Test
    func givenTunnel_whenPublishesDataCount_thenIsAvailable() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let sut = try await newTunnel(env)
        let stream = sut.snapshotsStream
        #expect(await stream.nextElement() == [:])

        let module = IPModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.connect(with: profile)
        let active = try await #require(stream.nextElement())

        let expectedXfer = ABI.ProfileTransfer(received: 500, sent: 700)
        #expect(active.first?.key == profile.id)
        let dataCount = DataCount(UInt64(expectedXfer.received), UInt64(expectedXfer.sent))
        env.setEnvironmentValue(dataCount, forKey: TunnelEnvironmentKeys.dataCount)
        try await Task.sleep(for: .milliseconds(200)) // > 0.1s to fetch environments
        let xfer = active[profile.id]?.environment?.dataCount.abiTransfer
        #expect(xfer == expectedXfer)
    }

    @Test
    func givenTunnelAndProcessor_whenInstall_thenProcessesProfile() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let processor = MockTunnelProcessor()
        let sut = try await newTunnel(env, processor: processor)
        let stream = sut.snapshotsStream
        #expect(await stream.nextElement() == [:])

        let module = IPModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        let active = try await #require(stream.nextElement())

        #expect(active.first?.key == profile.id)
//        #expect(processor.titleCount == 1) // unused by FakeTunnelStrategy
        #expect(processor.willInstallCount == 1)
    }

    @Test
    func givenTunnel_whenStatusChanges_thenConnectionStatusIsExpected() async throws {
        let env = SharedTunnelEnvironment(profileId: nil)
        let processor = MockTunnelProcessor()
        let sut = try await newTunnel(env, processor: processor)
        let stream = sut.snapshotsStream
        #expect(await stream.nextElement() == [:])

        let module = IPModule.Builder().build()
        let profile = try Profile.Builder(modules: [module]).build()

        try await sut.install(profile)
        let pulled = try await #require(stream.nextElement())

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

        // No connection status, tunnel status unaffected
        allTunnelStatuses.forEach {
            #expect($0.considering(nil) == $0)
        }

        // Has connection status
        var env = TunnelSnapshot.Environment()

        // Affected if .active
        let tunnelActive: TunnelStatus = .active
        env = env.with(connectionStatus: .connected)
        #expect(tunnelActive.considering(env) == .active)
        allConnectionStatuses
            .forEach {
                env = env.with(connectionStatus: $0)
                let statusWithEnv = tunnelActive.considering(env)
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

        // Unaffected otherwise
        allTunnelStatuses
            .filter {
                $0 != .active
            }
            .forEach {
                #expect($0.considering(env) == $0)
            }
    }

    @Test
    func givenTunnelInfo_whenEnvironmentConnectionStatusChanges_thenProfileStatusIsRecomputed() async throws {
        var env = TunnelSnapshot.Environment().with(connectionStatus: .connecting)
        let info = ABI.AppTunnelInfo(
            id: UniqueID(),
            isEnabled: true,
            tunnelStatus: .active,
            onDemand: false,
            environment: env
        )
        #expect(info.status == .connecting)

        env = env.with(connectionStatus: .connected)
        let updated = info.with(environment: env)
        #expect(updated.status == .connected)
    }
}

private extension Tunnel {
    func connect(with profile: Profile) async throws {
        try await install(profile, connect: true)
    }
}
