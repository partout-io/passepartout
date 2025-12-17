// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol APIMapper: Sendable {
    func index() async throws -> [Provider]

    func authenticate(_ module: ProviderModule, on deviceId: String) async throws -> ProviderModule

    func infrastructure(for module: ProviderModule, cache: ProviderCache?) async throws -> ProviderInfrastructure
}
