// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension Profile {
    public func abiHeaderWithBogusFlagsAndRequirements() -> ABI.AppProfileHeader {
        abiHeader(sharingFlags: [], requiredFeatures: [])
    }

    func abiHeader(
        sharingFlags: [ABI.ProfileSharingFlag],
        requiredFeatures: Set<ABI.AppFeature>
    ) -> ABI.AppProfileHeader {
        let primaryModuleType = activeModules
            .first(where: \.isPrimary)?
            .mainModuleType
        let secondaryModuleTypes = activeModules
            .filter { !$0.isPrimary }
            .map(\.moduleType)
            .nilIfEmpty

        return ABI.AppProfileHeader(
            id: id,
            name: name,
            moduleTypes: modules.map(\.moduleType),
            primaryModuleType: primaryModuleType,
            secondaryModuleTypes: secondaryModuleTypes,
            fingerprint: (attributes.fingerprint ?? UniqueID()).uuidString,
            sharingFlags: sharingFlags,
            requiredFeatures: requiredFeatures
        )
    }
}

private extension Module {
    var isPrimary: Bool {
        buildsConnection
    }

    var mainModuleType: ModuleType {
        moduleType
    }
}
