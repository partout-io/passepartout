// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

final class DefaultTunnelProcessor: Sendable {
    init() {
    }
}

extension DefaultTunnelProcessor: PacketTunnelProcessor {
    nonisolated func willProcess(_ profile: Profile) throws -> Profile {
        do {
            var builder = profile.builder()
            try builder.modules.forEach {
                guard var moduleBuilder = $0.moduleBuilder() as? OpenVPNModule.Builder else {
                    return
                }

                let preferences = builder.attributes.preferences(inModule: moduleBuilder.id)
                moduleBuilder.configurationBuilder?.remotes?.removeAll {
                    preferences.isExcludedEndpoint($0)
                }

                let module = try moduleBuilder.build()
                builder.saveModule(module)
            }
            return try builder.build()
        } catch {
            pp_log_id(profile.id, .app, .error, "Unable to process profile, revert to original: \(error)")
            return profile
        }
    }
}
