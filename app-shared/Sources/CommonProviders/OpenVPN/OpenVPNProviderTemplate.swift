// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public struct OpenVPNProviderTemplate: Codable, Sendable {
    public let configuration: OpenVPN.Configuration

    public let endpoints: [EndpointProtocol]

    public init(configuration: OpenVPN.Configuration, endpoints: [EndpointProtocol]) {
        self.configuration = configuration
        self.endpoints = endpoints
    }
}

extension OpenVPNProviderTemplate {
    public struct Options: ProviderOptions {
        public var credentials: OpenVPN.Credentials?

        public var excludingHostname = false

        public init() {
        }
    }
}

extension OpenVPNProviderTemplate: ProviderTemplateCompiler {
    public func compiled(
        _ ctx: PartoutLoggerContext,
        moduleId: UniqueID,
        entity: ProviderEntity,
        options: Options?,
        userInfo: Void?
    ) throws -> OpenVPNModule {
        var configurationBuilder = configuration.builder()
        configurationBuilder.authUserPass = true
        configurationBuilder.remotes = try remotes(
            ctx,
            with: entity.server,
            excludingHostname: options?.excludingHostname == true
        )

        // enforce default gateway
        configurationBuilder.routingPolicies = [.IPv4, .IPv6]

        var builder = OpenVPNModule.Builder(id: moduleId)
        builder.configurationBuilder = configurationBuilder
        if let credentials = options?.credentials {
            builder.credentials = credentials
        }
        return try builder.build()
    }
}

private extension OpenVPNProviderTemplate {
    func remotes(_ ctx: PartoutLoggerContext, with server: ProviderServer, excludingHostname: Bool) throws -> [ExtendedEndpoint] {
        var remotes: [ExtendedEndpoint] = []

        if !excludingHostname, let hostname = server.hostname {
            try endpoints.forEach { ep in
                remotes.append(try .init(hostname, ep))
            }
        }
        endpoints.forEach { ep in
            server.ipAddresses?.forEach { data in
                guard let addr = Address(data: data) else { return }
                remotes.append(.init(addr, ep))
            }
        }
        guard !remotes.isEmpty else {
            pp_log(ctx, .providers, .error, "Excluding hostname but server has no ipAddresses either")
            throw PartoutError(.exhaustedEndpoints)
        }

        return remotes
    }
}
