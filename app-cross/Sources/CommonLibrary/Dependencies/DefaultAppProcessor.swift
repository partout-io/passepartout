// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: ProfileProcessor

final class DefaultProfileProcessor: ProfileProcessor, Sendable {
    private let iapManager: IAPManager?

    init(iapManager: IAPManager?) {
        self.iapManager = iapManager
    }

    func isIncluded(_ profile: Profile) -> Bool {
#if os(tvOS)
        profile.attributes.isAvailableForTV == true
#else
        true
#endif
    }

    func requiredFeatures(_ profile: Profile) -> Set<ABI.AppFeature>? {
        do {
            try iapManager?.verify(profile)
            return nil
        } catch ABI.AppError.ineligibleProfile(let requiredFeatures) {
            return requiredFeatures
        } catch {
            return nil
        }
    }
}

// MARK: - AppTunnelProcessor

final class DefaultAppTunnelProcessor: AppTunnelProcessor, Sendable {
    private let apiManager: APIManager?

    private let resolver: Resolver

    private let extensionInstaller: ExtensionInstaller?

    private let providerServerSorter: ProviderServerParameters.Sorter

    init(
        apiManager: APIManager?,
        resolver: Resolver,
        extensionInstaller: ExtensionInstaller?,
        providerServerSorter: @escaping @Sendable ProviderServerParameters.Sorter
    ) {
        self.apiManager = apiManager
        self.resolver = resolver
        self.extensionInstaller = extensionInstaller
        self.providerServerSorter = providerServerSorter
    }

    nonisolated func willInstall(
        _ preProfile: Profile,
        connect: Bool,
        force: Bool
    ) async throws -> Profile? {
        var profile = preProfile

        // Trigger user input if profile is interactive
        if connect {
            guard !profile.isInteractive || force else {
                throw ABI.AppError.interactiveLogin
            }
        }

        // Install extension before proceeding
        if let extensionInstaller {
            if extensionInstaller.currentResult == .success {
                pspLog(.core, .info, "Extensions: already installed")
            } else {
                pspLog(.core, .info, "Extensions: install...")
                do {
                    let result = try await extensionInstaller.install()
                    switch result {
                    case .success:
                        break
                    default:
                        throw ABI.AppError.systemExtension(result)
                    }
                    pspLog(.core, .info, "Extensions: installation result is \(result)")
                } catch {
                    pspLog(.core, .error, "Extensions: installation error: \(error)")
                }
            }
        }

        // Apply provider preprocessing if APIManager provided
        if let apiManager {
            // Apply connection heuristic
            do {
                if let builder = profile.activeProviderModule?.moduleBuilder() as? ProviderModule.Builder,
                   let heuristic = builder.entity?.heuristic {
                    pspLog(.core, .info, "Apply connection heuristic: \(heuristic)")
                    profile.activeProviderModule?.entity.map {
                        pspLog(.core, .info, "\tOld server: \($0.server)")
                    }
                    profile = try await preProfile.withNewServer(using: heuristic, apiManager: apiManager, sort: providerServerSorter)
                    profile.activeProviderModule?.entity.map {
                        pspLog(.core, .info, "\tNew server: \($0.server)")
                    }
                }
            } catch {
                pspLog(.core, .error, "Unable to pick new provider server: \(error)")
            }

            // Validate provider modules. Do not commit resolved
            // profile, the tunnel requires the original profile.
            do {
                _ = try resolver.resolvedProfile(profile)
            } catch {
                pspLog(.core, .error, "Unable to inject provider modules: \(error)")
                throw error
            }
        }

        // Return processed profile
        return profile
    }
}

// MARK: Heuristics

private extension Profile {
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
