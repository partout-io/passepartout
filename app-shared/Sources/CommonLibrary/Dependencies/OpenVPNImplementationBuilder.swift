// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if PSP_CROSS || canImport(PartoutOpenVPNConnection)
import Partout

struct OpenVPNImplementationBuilder: Sendable {
    private let distributionTarget: ABI.DistributionTarget

    private let configBlock: @Sendable () -> Set<ABI.ConfigFlag>

    init(distributionTarget: ABI.DistributionTarget, configBlock: @escaping @Sendable () -> Set<ABI.ConfigFlag>) {
        self.distributionTarget = distributionTarget
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
        // TODO: #218, this directory must be per-profile
        guard let cachesURL = FileManager.default.miniTemporaryDirectory as? URL else {
            fatalError("Unexpected cachesURL type")
        }
        let ctx = PartoutLoggerContext(parameters.profile.id)
        var options = OpenVPNConnection.Options()
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
#endif
