// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonProvidersCore
#endif
import Partout

public struct WireGuardProviderTemplate: Hashable, Codable, Sendable {
    public struct UserInfo: Sendable {
        public let deviceId: String

        public init(deviceId: String) {
            self.deviceId = deviceId
        }
    }

    public let ports: [UInt16]

    public init(ports: [UInt16]) {
        self.ports = ports
    }
}

extension WireGuardProviderTemplate: ProviderTemplateCompiler {
    public func compiled(
        _ ctx: PartoutLoggerContext,
        moduleId: UniqueID,
        entity: ProviderEntity,
        options: WireGuardProviderStorage?,
        userInfo: UserInfo?
    ) throws -> WireGuardModule {

        // template preconditions
        guard let anyPort = ports.randomElement() else {
            throw PartoutError(.Providers.missingOption, "ports")
        }

        // module preconditions
        guard let deviceId = userInfo?.deviceId else {
            throw PartoutError(.Providers.missingOption, "userInfo.deviceId")
        }
        guard let session = options?.sessions?[deviceId] else {
            throw PartoutError(.Providers.missingOption, "session")
        }
        guard let peer = session.peer else {
            throw PartoutError(.Providers.missingOption, "session.peer")
        }

        // server preconditions
        guard let serverPublicKey = entity.server.userInfo?["wgPublicKey"] as? String else {
            throw PartoutError(.Providers.missingOption, "entity.server.wgPublicKey")
        }
        let serverPreSharedKey = entity.server.userInfo?["wgPreSharedKey"] as? String

        // pick a random address preferring IP address over hostname if available
        let anyAddress = entity.server.ipAddresses?.randomElement().map {
            Address(data: $0)
        } ?? entity.server.hostname.map {
            Address(rawValue: $0)
        } ?? nil
        guard let anyAddress else {
            throw PartoutError(.Providers.missingOption, "entity.server.allAddresses")
        }

        // local interface from session
        var configurationBuilder = WireGuard.Configuration.Builder(privateKey: session.privateKey)
        configurationBuilder.interface.addresses = peer.addresses

        // remote interfaces from infrastructure
        configurationBuilder.peers = {
            var peer = WireGuard.RemoteInterface.Builder(publicKey: serverPublicKey)
            peer.preSharedKey = serverPreSharedKey
            peer.endpoint = "\(anyAddress):\(anyPort)"
            peer.allowedIPs = ["0.0.0.0/0", "::/0"]
            return [peer]
        }()

        var builder = WireGuardModule.Builder(id: moduleId)
        builder.configurationBuilder = configurationBuilder
        return try builder.build()
    }
}
