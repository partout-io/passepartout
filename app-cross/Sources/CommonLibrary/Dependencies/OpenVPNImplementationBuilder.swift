// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

struct OpenVPNImplementationBuilder: Sendable {
    private let distributionTarget: ABI.DistributionTarget

    private let cachesURL: URL

    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>

    init(
        distributionTarget: ABI.DistributionTarget,
        cachesURL: URL,
        configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>
    ) {
        self.distributionTarget = distributionTarget
        self.cachesURL = cachesURL
        self.configBlock = configBlock
    }

    func build() -> OpenVPNModule.Implementation {
        OpenVPNModule.Implementation(
            importerBlock: { StandardOpenVPNParser() },
            connectionBlock: {
                try crossConnection(with: $0, module: $1)
            }
        )
    }
}

private extension OpenVPNImplementationBuilder {
    func crossConnection(
        with parameters: ConnectionParameters,
        module: OpenVPNModule
    ) throws -> Connection {
        let ctx = PartoutLoggerContext(parameters.profile.id)
        var options = OpenVPNConnectionOptions()
        options.writeTimeout = TimeInterval(parameters.options.linkWriteTimeout) / 1000.0
        options.minDataCountInterval = TimeInterval(parameters.options.minDataCountInterval) / 1000.0
#if !PSP_CROSS
        let flags = configBlock()
        if flags.contains(.ovpnCrossV2) || flags.contains(.bsdSockets) {
            return try _OpenVPNConnectionV2(
                ctx,
                parameters: parameters,
                module: module,
                cachesURL: cachesURL,
                options: options
            )
        } else {
            return try _OpenVPNConnectionV1(
                ctx,
                parameters: parameters,
                module: module,
                cachesURL: cachesURL,
                options: options
            )
        }
#else
        return try _OpenVPNConnectionV2(
            ctx,
            parameters: parameters,
            module: module,
            cachesURL: cachesURL,
            options: options
        )
#endif
    }
}
