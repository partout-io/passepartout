// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation
import Partout

final class DefaultAppProcessor: Sendable {
    private let apiManager: APIManager

    private let iapManager: IAPManager

    private let registry: Registry

    private let title: @Sendable (Profile) -> String

    init(
        apiManager: APIManager,
        iapManager: IAPManager,
        registry: Registry,
        title: @escaping @Sendable (Profile) -> String
    ) {
        self.apiManager = apiManager
        self.iapManager = iapManager
        self.registry = registry
        self.title = title
    }
}

extension DefaultAppProcessor: ProfileProcessor {
    func isIncluded(_ profile: Profile) -> Bool {
#if os(tvOS)
        profile.attributes.isAvailableForTV == true
#else
        true
#endif
    }

    func preview(from profile: Profile) -> ABI.ProfilePreview {
        profile.localizedPreview
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        do {
            try iapManager.verify(profile)
            return nil
        } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {
            return requiredFeatures
        } catch {
            return nil
        }
    }

    func willRebuild(_ builder: Profile.Builder) throws -> Profile.Builder {
        builder
    }
}

extension DefaultAppProcessor: AppTunnelProcessor {
    nonisolated func title(for profile: Profile) -> String {
        title(profile)
    }

    nonisolated func willInstall(_ profile: Profile) async throws -> Profile {

        // apply connection heuristic
        var newProfile = profile
        do {
            if let builder = newProfile.activeProviderModule?.moduleBuilder() as? ProviderModule.Builder,
               let heuristic = builder.entity?.heuristic {
                pp_log_g(.App.core, .info, "Apply connection heuristic: \(heuristic)")
                newProfile.activeProviderModule?.entity.map {
                    pp_log_g(.App.core, .info, "\tOld server: \($0.server)")
                }
                newProfile = try await profile.withNewServer(using: heuristic, apiManager: apiManager)
                newProfile.activeProviderModule?.entity.map {
                    pp_log_g(.App.core, .info, "\tNew server: \($0.server)")
                }
            }
        } catch {
            pp_log_g(.App.core, .error, "Unable to pick new provider server: \(error)")
        }

        // validate provider modules
        do {
            _ = try registry.resolvedProfile(newProfile)
            return newProfile
        } catch {
            pp_log_g(.App.core, .error, "Unable to inject provider modules: \(error)")
            throw error
        }
    }
}

// MARK: - Heuristics

// TODO: #1263, these should be implemented in the library

private extension Profile {

    @MainActor
    func withNewServer(using heuristic: ProviderHeuristic, apiManager: APIManager) async throws -> Profile {
        guard var providerModule = activeProviderModule?.moduleBuilder() as? ProviderModule.Builder else {
            return self
        }
        try await providerModule.setRandomServer(using: heuristic, apiManager: apiManager)

        var newBuilder = builder()
        newBuilder.saveModule(try providerModule.build())
        return try newBuilder.build()
    }
}

private extension ProviderModule.Builder {

    @MainActor
    mutating func setRandomServer(using heuristic: ProviderHeuristic, apiManager: APIManager) async throws {
        guard let providerId, let providerModuleType, let entity else {
            return
        }
        let module = try ProviderModule.Builder(providerId: providerId, providerModuleType: providerModuleType).build()
        let repo = try await apiManager.providerRepository(for: module) {
            $0.sort(using: $1.sortingComparators)
        }
        let providerManager = ProviderManager()
        try await providerManager.setRepository(repo, for: providerModuleType)

        var filters = ProviderFilters()
        filters.categoryName = entity.server.metadata.categoryName
        filters.presetId = entity.preset.presetId

        switch heuristic {
        case .exact(let server):
            filters.serverIds = [server.serverId]
        case .sameCountry(let code):
            filters.countryCode = code
        case .sameRegion(let region):
            filters.countryCode = region.countryCode
            filters.area = region.area
        }

        var servers = try await providerManager.filteredServers(with: filters)
        servers.removeAll {
            $0.serverId == entity.server.serverId
        }
        guard let randomServer = servers.randomElement() else {
            return
        }
        self.entity = ProviderEntity(
            server: randomServer,
            preset: entity.preset,
            heuristic: entity.heuristic
        )
    }
}
