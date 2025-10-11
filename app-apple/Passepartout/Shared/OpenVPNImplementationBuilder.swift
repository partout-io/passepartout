// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

struct OpenVPNImplementationBuilder: Sendable {
    private let distributionTarget: DistributionTarget

    private let configBlock: @Sendable () -> Set<ConfigFlag>

    init(distributionTarget: DistributionTarget, configBlock: @escaping @Sendable () -> Set<ConfigFlag>) {
        self.distributionTarget = distributionTarget
        self.configBlock = configBlock
    }

    func build() -> OpenVPNModule.Implementation {
        OpenVPNModule.Implementation(
            importerBlock: { StandardOpenVPNParser() },
            connectionBlock: {
                // FIXME: ###, Made redundant by configBlock?
                let preferences = $0.options.userInfo as? AppPreferenceValues
                if preferences?.isFlagEnabled(.ovpnCrossConnection) == true {
                    return try crossConnection(with: $0, module: $1)
                } else {
                    return try legacyConnection(with: $0, module: $1)
                }
            }
        )
    }
}

private extension OpenVPNImplementationBuilder {

    // TODO: #218, this directory must be per-profile
    var cachesURL: URL {
        FileManager.default.temporaryDirectory
    }

    func legacyConnection(
        with parameters: ConnectionParameters,
        module: OpenVPNModule
    ) throws -> Connection {
        let ctx = PartoutLoggerContext(parameters.profile.id)
        var options = OpenVPN.ConnectionOptions()
        options.writeTimeout = TimeInterval(parameters.options.linkWriteTimeout) / 1000.0
        options.minDataCountInterval = TimeInterval(parameters.options.minDataCountInterval) / 1000.0
        return try LegacyOpenVPNConnection(
            ctx,
            parameters: parameters,
            module: module,
            prng: PlatformPRNG(),
            dns: SimpleDNSResolver {
                POSIXDNSStrategy(hostname: $0)
            },
            options: options,
            cachesURL: cachesURL
        )
    }

    func crossConnection(
        with parameters: ConnectionParameters,
        module: OpenVPNModule
    ) throws -> Connection {
        let ctx = PartoutLoggerContext(parameters.profile.id)
        var options = OpenVPN.ConnectionOptions()
        options.writeTimeout = TimeInterval(parameters.options.linkWriteTimeout) / 1000.0
        options.minDataCountInterval = TimeInterval(parameters.options.minDataCountInterval) / 1000.0
        return try OpenVPNConnection(
            ctx,
            parameters: parameters,
            module: module,
            cachesURL: cachesURL,
            options: options
        )
    }
}
