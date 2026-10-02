// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import os
import Partout
import Testing
@testable import TunnelLibrary

// activeTunnels is process-global, so context tests run serially and stop after a start that tracks.
@MainActor
@Suite(.serialized)
struct TunnelContextTests {
    @Test(arguments: InteractiveOpenVPN.allCases)
    func givenInteractiveProfile_whenSystemStarts_thenRejectsBeforeBackend(_ kind: InteractiveOpenVPN) async throws {
        let profile = try kind.makeProfile()
        let module = try #require(profile.activeModules.first as? OpenVPNModule)
        #expect(profile.isInteractive)
        #expect(module.credentials?.otpMethod == kind.otpMethod)
        #expect(module.credentials?.otp == kind.otp)

        let backend = RecordingTunnelBackend()
        let environment = SharedTunnelEnvironment(profileId: profile.id)
        environment.setEnvironmentValue(ConnectionStatus.connecting, forKey: TunnelEnvironmentKeys.connectionStatus)
        environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)

        var rejected = false
        try await withContext(profile: profile, backend: backend, environment: environment) { sut, environment in
            do {
                try await sut.start(isInteractive: false)
            } catch ABI.AppError.interactiveLogin {
                rejected = true
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            #expect(rejected)
            #expect(backend.startCount == 0)
            #expect(backend.holdCount == 0)
            #expect(environment.environmentValue(forKey: TunnelEnvironmentKeys.connectionStatus) == .disconnected)
            #expect(environment.environmentValue(forKey: TunnelEnvironmentKeys.lastErrorCode) == "App.interactiveLogin")
            #expect(environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true)
        }
    }

    @Test(arguments: InteractiveOpenVPN.allCases)
    func givenRejectedSystemStart_whenAppStartsSameContext_thenConnects(_ kind: InteractiveOpenVPN) async throws {
        let profile = try kind.makeProfile()
        let backend = RecordingTunnelBackend()
        try await withContext(
            profile: profile,
            backend: backend,
            iap: kind.requiresPurchase ? makeDeferredIAP() : nil
        ) { sut, _ in
            do {
                try await sut.start(isInteractive: false)
                Issue.record("Expected interactive login rejection")
            } catch ABI.AppError.interactiveLogin {
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            try await sut.start(isInteractive: true)

            #expect(backend.startCount == 1)
            #expect(backend.holdCount == 0)
        }
    }

    @Test(arguments: InteractiveOpenVPN.allCases)
    func givenSubmittedCredentials_whenAppStarts_thenReachesBackend(_ kind: InteractiveOpenVPN) async throws {
        let profile = try kind.makeProfile()
        let module = try #require(profile.activeModules.first as? OpenVPNModule)
        #expect(module.isInteractive)
        #expect(module.credentials?.username == "user")
        #expect(module.credentials?.password == "password")
        #expect(module.credentials?.otpMethod == kind.otpMethod)

        let backend = RecordingTunnelBackend()
        try await withContext(
            profile: profile,
            backend: backend,
            iap: kind.requiresPurchase ? makeDeferredIAP() : nil
        ) { sut, _ in
            try await sut.start(isInteractive: true)
        }

        #expect(backend.startCount == 1)
        #expect(backend.holdCount == 0)
    }

    @Test
    func givenNoninteractiveProfile_whenSystemStarts_thenStartsBackend() async throws {
        let profile = try makeOpenVPNProfile(isInteractive: false, otpMethod: .none, otp: nil)
        #expect(!profile.isInteractive)

        let backend = RecordingTunnelBackend()
        try await withContext(profile: profile, backend: backend) { sut, _ in
            try await sut.start(isInteractive: false)
        }

        #expect(backend.startCount == 1)
        #expect(backend.holdCount == 0)
    }

    @Test
    func givenInactiveInteractiveModule_whenSystemStarts_thenFollowsProfileInteractivity() async throws {
        let active = try makeOpenVPNModule(isInteractive: false, otpMethod: .none, otp: nil)
        let inactive = try makeOpenVPNModule(isInteractive: true, otpMethod: .append, otp: "123456")
        let profile = try Profile.Builder(
            modules: [active, inactive],
            activeModulesIds: [active.id]
        ).build()

        let hasInteractiveModule = profile.modules.contains { $0.isInteractive }
        #expect(!profile.isInteractive)
        #expect(hasInteractiveModule)
        #expect(profile.features.isEmpty)

        let backend = RecordingTunnelBackend()
        try await withContext(profile: profile, backend: backend) { sut, _ in
            try await sut.start(isInteractive: false)
        }

        #expect(backend.startCount == 1)
        #expect(backend.holdCount == 0)
    }

    @Test
    func givenHoldFlag_whenSystemStartsPermittedProfile_thenHoldsWithoutStarting() async throws {
        let profile = try makeOpenVPNProfile(isInteractive: false, otpMethod: .none, otp: nil)
        let backend = RecordingTunnelBackend()
        let environment = SharedTunnelEnvironment(profileId: profile.id)
        environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
        try await withContext(profile: profile, backend: backend, environment: environment) { sut, environment in
            try await sut.start(isInteractive: false)

            #expect(backend.holdCount == 1)
            #expect(backend.startCount == 0)
            #expect(environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == true)
        }
    }

    @Test(arguments: [false, true])
    func givenHoldFlag_whenPermittedInteractiveStart_thenClearsHoldAndStarts(_ profileIsInteractive: Bool) async throws {
        let profile = try makeOpenVPNProfile(
            isInteractive: profileIsInteractive,
            otpMethod: .none,
            otp: nil
        )
        let backend = RecordingTunnelBackend()
        let environment = SharedTunnelEnvironment(profileId: profile.id)
        environment.setEnvironmentValue(true, forKey: TunnelEnvironmentKeys.holdFlag)
        try await withContext(profile: profile, backend: backend, environment: environment) { sut, environment in
            try await sut.start(isInteractive: true)

            #expect(backend.startCount == 1)
            #expect(backend.holdCount == 0)
            #expect(environment.environmentValue(forKey: TunnelEnvironmentKeys.holdFlag) == nil)
        }
    }

    @Test
    func givenBackendFailure_whenStarting_thenPropagatesUnchanged() async throws {
        let profile = try makeOpenVPNProfile(isInteractive: false, otpMethod: .none, otp: nil)
        let backend = RecordingTunnelBackend()
        backend.failure = .failed

        var propagated = false
        try await withContext(profile: profile, backend: backend) { sut, _ in
            do {
                try await sut.start(isInteractive: false)
            } catch RecordingTunnelBackend.Failure.failed {
                propagated = true
            } catch {
                Issue.record("Unexpected error: \(error)")
            }

            #expect(propagated)
            #expect(backend.startCount == 1)
            #expect(backend.holdCount == 0)
        }
    }
}

enum InteractiveOpenVPN: String, CaseIterable, Sendable {
    case appendOTP
    case encodeOTP
    case password

    var otpMethod: OpenVPN.Credentials.OTPMethod {
        switch self {
        case .appendOTP:
            return .append
        case .encodeOTP:
            return .encode
        case .password:
            return .none
        }
    }

    var otp: String? {
        switch self {
        case .appendOTP:
            return "123456"
        case .encodeOTP:
            return "654321"
        case .password:
            return nil
        }
    }

    var requiresPurchase: Bool {
        otpMethod != .none
    }

    func makeProfile() throws -> Profile {
        try makeOpenVPNProfile(isInteractive: true, otpMethod: otpMethod, otp: otp)
    }
}

@MainActor
private func makeContext(
    profile: Profile,
    backend: RecordingTunnelBackend,
    environment: SharedTunnelEnvironment,
    iap: TunnelContext.IAP? = nil
) -> TunnelContext {
    TunnelContext(
        backend: backend,
        originalProfile: profile,
        environment: environment,
        iap: iap
    )
}

@MainActor
private func withContext(
    profile: Profile,
    backend: RecordingTunnelBackend,
    environment: SharedTunnelEnvironment? = nil,
    iap: TunnelContext.IAP? = nil,
    _ body: (TunnelContext, SharedTunnelEnvironment) async throws -> Void
) async throws {
    let resolvedEnvironment = environment ?? SharedTunnelEnvironment(profileId: profile.id)
    let sut = makeContext(
        profile: profile,
        backend: backend,
        environment: resolvedEnvironment,
        iap: iap
    )
    do {
        try await body(sut, resolvedEnvironment)
    } catch {
        await sut.stop()
        throw error
    }
    await sut.stop()
}

private func makeDeferredIAP() -> TunnelContext.IAP {
    TunnelContext.IAP(
        manager: IAPManager(),
        skipsPurchases: true,
        verificationParameters: .init(
            defaultDelay: 86_400,
            tvDelay: 86_400,
            interval: 86_400,
            attempts: 1,
            retryInterval: 86_400
        )
    )
}

private func makeOpenVPNProfile(
    isInteractive: Bool,
    otpMethod: OpenVPN.Credentials.OTPMethod,
    otp: String?
) throws -> Profile {
    let module = try makeOpenVPNModule(
        isInteractive: isInteractive,
        otpMethod: otpMethod,
        otp: otp
    )
    return try Profile.Builder(
        modules: [module],
        activeModulesIds: [module.id]
    ).build()
}

private func makeOpenVPNModule(
    isInteractive: Bool,
    otpMethod: OpenVPN.Credentials.OTPMethod,
    otp: String?
) throws -> OpenVPNModule {
    var configuration = OpenVPN.Configuration.Builder()
    configuration.ca = OpenVPN.CryptoContainer(pem: "ca")
    configuration.authUserPass = true
    configuration.remotes = [
        try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.udp, 1194))
    ]
    let credentials = OpenVPN.Credentials.Builder(
        username: "user",
        password: "password",
        otpMethod: otpMethod,
        otp: otp
    ).build()
    return try OpenVPNModule.Builder(
        configurationBuilder: configuration,
        credentials: credentials,
        isInteractive: isInteractive
    ).build()
}

private final class RecordingTunnelBackend: TunnelBackendProtocol, @unchecked Sendable {
    enum Failure: Error, Equatable, Sendable {
        case failed
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var failure: Failure? {
        get { state.withLock { $0.failure } }
        set { state.withLock { $0.failure = newValue } }
    }

    var startCount: Int {
        state.withLock { $0.startCount }
    }

    var holdCount: Int {
        state.withLock { $0.holdCount }
    }

    func start() async throws {
        let failure = state.withLock { state -> Failure? in
            state.startCount += 1
            return state.failure
        }
        if let failure {
            throw failure
        }
    }

    func stop() async {
        state.withLock { $0.stopCount += 1 }
    }

    func hold() async {
        state.withLock { $0.holdCount += 1 }
    }

    func sendMessage(_ messageData: Data) async throws -> Data? {
        nil
    }

    private struct State: Sendable {
        var startCount = 0
        var holdCount = 0
        var stopCount = 0
        var failure: Failure?
    }
}
