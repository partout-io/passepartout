// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import CommonProvidersCore
#endif
import Foundation

public struct ProviderInfrastructure: Decodable, Sendable {
    public let presets: [ProviderPreset]

    public let servers: [ProviderServer]

    public let cache: ProviderCache?

    public init(presets: [ProviderPreset], servers: [ProviderServer], cache: ProviderCache?) {
        self.presets = presets
        self.servers = servers
        self.cache = cache
    }
}
