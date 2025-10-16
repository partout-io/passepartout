// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonProvidersCore
import Foundation

public protocol ProviderRepository: AnyObject, Sendable {
    var providerId: ProviderID { get }

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions

    func filteredServers(with parameters: ProviderServerParameters?) async throws -> [ProviderServer]
}
