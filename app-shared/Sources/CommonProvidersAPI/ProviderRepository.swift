// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol ProviderRepository: AnyObject, Sendable {
    var providerId: ProviderID { get }

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions

    func filteredServers(with parameters: ProviderServerParameters?) async throws -> [ProviderServer]
}
