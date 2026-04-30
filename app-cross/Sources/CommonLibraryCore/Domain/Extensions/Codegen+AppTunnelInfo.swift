// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppTunnelInfo {
    public init(
        id: String,
        isEnabled: Bool,
        tunnelStatus: TunnelStatus,
        onDemand: Bool,
        environment: TunnelEnvironmentReader?
    ) {
        self.id = id
        self.isEnabled = isEnabled
        // Merge Partout status with environment to compute profile status
        status = tunnelStatus.considering(environment).abiStatus
        partoutTunnelStatus = tunnelStatus.rawValue
        self.onDemand = onDemand
        transfer = environment?.transfer
        lastErrorCode = environment?.lastErrorCode
    }

    public var tunnelStatus: TunnelStatus {
        TunnelStatus(rawValue: partoutTunnelStatus) ?? .inactive
    }

    public func with(environment: TunnelEnvironmentReader) -> Self {
        Self(
            id: id,
            isEnabled: isEnabled,
            tunnelStatus: tunnelStatus,
            onDemand: onDemand,
            environment: environment
        )
    }
}

private extension TunnelEnvironmentReader {
    var transfer: ABI.ProfileTransfer? {
        environmentValue(
            forKey: TunnelEnvironmentKeys.dataCount
        )?.abiTransfer
    }

    var lastErrorCode: String? {
        environmentValue(
            forKey: TunnelEnvironmentKeys.lastErrorCode
        )?.rawValue
    }
}
