// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: ProfileProcessor

final class DefaultProfileProcessor: ProfileProcessor, Sendable {
    private let iapManager: IAPManager?

    private let preview: @Sendable (Profile) -> ABI.ProfilePreview

    init(
        iapManager: IAPManager?,
        preview: @escaping @Sendable (Profile) -> ABI.ProfilePreview
    ) {
        self.iapManager = iapManager
        self.preview = preview
    }

    func isIncluded(_ profile: Profile) -> Bool {
#if os(tvOS)
        profile.attributes.isAvailableForTV == true
#else
        true
#endif
    }

    func preview(from profile: Profile) -> ABI.ProfilePreview {
        preview(profile)
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        do {
            try iapManager?.verify(ABI.AppProfile(native: profile))
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

// MARK: - AppTunnelProcessor

final class DefaultAppTunnelProcessor: AppTunnelProcessor, Sendable {
    private let logger: AppLogger

    private let apiManager: APIManager?

    private let registry: Registry

    private let title: @Sendable (Profile) -> String

    private let providerServerSorter: ProviderServerParameters.Sorter

    init(
        _ logger: AppLogger,
        apiManager: APIManager?,
        registry: Registry,
        title: @escaping @Sendable (Profile) -> String,
        providerServerSorter: @escaping @Sendable ProviderServerParameters.Sorter
    ) {
        self.logger = logger
        self.apiManager = apiManager
        self.registry = registry
        self.title = title
        self.providerServerSorter = providerServerSorter
    }

    nonisolated func title(for profile: Profile) -> String {
        title(profile)
    }

    nonisolated func willInstall(_ profile: Profile) async throws -> Profile {
        guard let apiManager else {
            return profile
        }

        // Apply connection heuristic
        var newProfile = profile
        do {
            if let builder = newProfile.activeProviderModule?.moduleBuilder() as? ProviderModule.Builder,
               let heuristic = builder.entity?.heuristic {
                logger.log(.core, .info, "Apply connection heuristic: \(heuristic)")
                newProfile.activeProviderModule?.entity.map {
                    logger.log(.core, .info, "\tOld server: \($0.server)")
                }
                newProfile = try await profile.withNewServer(using: heuristic, apiManager: apiManager, sort: providerServerSorter)
                newProfile.activeProviderModule?.entity.map {
                    logger.log(.core, .info, "\tNew server: \($0.server)")
                }
            }
        } catch {
            logger.log(.core, .error, "Unable to pick new provider server: \(error)")
        }

        // Validate provider modules
        do {
            _ = try registry.resolvedProfile(newProfile)
            return newProfile
        } catch {
            logger.log(.core, .error, "Unable to inject provider modules: \(error)")
            throw error
        }
    }
}

// MARK: Heuristics

private extension Profile {
    @MainActor
    func withNewServer(using heuristic: ProviderHeuristic, apiManager: APIManager, sort: @escaping ProviderServerParameters.Sorter) async throws -> Profile {
        guard var providerModule = activeProviderModule?.moduleBuilder() as? ProviderModule.Builder else {
            return self
        }
        try await providerModule.setRandomServer(using: heuristic, apiManager: apiManager, sort: sort)

        var newBuilder = builder()
        newBuilder.saveModule(try providerModule.build())
        return try newBuilder.build()
    }
}

private extension ProviderModule.Builder {
    @MainActor
    mutating func setRandomServer(using heuristic: ProviderHeuristic, apiManager: APIManager, sort: @escaping ProviderServerParameters.Sorter) async throws {
        guard let providerId, let providerModuleType, let entity else {
            return
        }
        let module = try ProviderModule.Builder(providerId: providerId, providerModuleType: providerModuleType).build()
        let repo = try await apiManager.providerRepository(for: module, sort: sort)
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
