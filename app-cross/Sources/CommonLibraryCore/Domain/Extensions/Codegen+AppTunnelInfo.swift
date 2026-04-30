// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI.AppTunnelInfo {
    public init(
        rawId: String,
        isEnabled: Bool,
        tunnelStatus: TunnelStatus,
        onDemand: Bool,
        environment: TunnelEnvironmentReader?
    ) {
        self.rawId = rawId
        self.isEnabled = isEnabled
        // Merge Partout status with environment to compute profile status
        status = tunnelStatus.considering(environment).abiStatus
        self.rawTunnelStatus = tunnelStatus.rawValue
        self.onDemand = onDemand
        transfer = environment?.transfer
        rawLastErrorCode = environment?.lastErrorCode
    }

    public func with(environment: TunnelEnvironmentReader) -> Self {
        Self(
            rawId: rawId,
            isEnabled: isEnabled,
            tunnelStatus: tunnelStatus,
            onDemand: onDemand,
            environment: environment
        )
    }

    public var id: Profile.ID {
        guard let id = Profile.ID(uuidString: rawId) else {
            fatalError("rawId is not an UUID")
        }
        return id
    }

    public var tunnelStatus: TunnelStatus {
        TunnelStatus(rawValue: rawTunnelStatus) ?? .inactive
    }

    public var lastErrorCode: PartoutError.Code? {
        rawLastErrorCode.map {
            PartoutError.Code(rawValue: $0)
        }
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
