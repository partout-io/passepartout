// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import CommonProvidersCore
#endif
import Foundation
import Partout

#if canImport(Combine)
import Combine

extension APIManager: ObservableObject {
}
#endif

@MainActor
public final class APIManager {
    private enum PendingService: Hashable {
        case index

        case provider(ProviderID)
    }

    private let ctx: PartoutLoggerContext

    private let apis: [APIMapper]

    private let repository: APIRepository

#if canImport(Combine)
    @Published
#endif
    public private(set) var providers: [Provider]

#if canImport(Combine)
    @Published
#endif
    public private(set) var cache: [ProviderID: ProviderCache]

#if canImport(Combine)
    @Published
#endif
    private var pendingServices: Set<PendingService> = []

    private var subscriptions: [Task<Void, Never>]

    public var isLoading: Bool {
        !pendingServices.isEmpty
    }

    public init(_ ctx: PartoutLoggerContext, from apis: [APIMapper], repository: APIRepository) {
        self.ctx = ctx
        self.apis = apis
        self.repository = repository
        providers = []
        cache = [:]
        subscriptions = []

        observeObjects()
    }

    public func fetchIndex() async throws {
        let service: PendingService = .index
        guard !pendingServices.contains(service) else {
            pp_log(ctx, .providers, .error, "Discard fetchIndex, another .index is pending")
            return
        }
        pendingServices.insert(service)
        defer {
            pendingServices.remove(service)
        }

        var lastError: Error?
        for api in apis {
            do {
                let index = try await api.index()
                try Task.checkCancellation()
                try await repository.store(index)
#if canImport(Combine)
                objectWillChange.send()
#endif
                return
            } catch {
                lastError = error
                pp_log(ctx, .providers, .error, "Unable to fetch index: \(error)")
                try Task.checkCancellation()
            }
        }
        if let lastError {
            throw lastError
        }
    }

    public func authenticate(_ module: ProviderModule, on deviceId: String) async throws -> ProviderModule {
        guard let api = apis.first else {
            throw PartoutError(.authentication)
        }
        pp_log(ctx, .providers, .info, "Authenticating with \(module.providerId) for \(module.providerModuleType)")
        return try await api.authenticate(module, on: deviceId)
    }

    public func fetchInfrastructure(for module: ProviderModule) async throws {
        let service: PendingService = .provider(module.providerId)
        guard !pendingServices.contains(service) else {
            pp_log(ctx, .providers, .error, "Discard fetchProviderInfrastructure, another .provider(\(module.providerId)) is pending")
            return
        }
        pendingServices.insert(service)
        defer {
            pendingServices.remove(service)
        }

        var lastError: Error?
        for api in apis {
            do {
                let lastCache = cache[module.providerId]
                let infrastructure = try await api.infrastructure(for: module, cache: lastCache)
                try Task.checkCancellation()
                try await repository.store(infrastructure, for: module.providerId)
#if canImport(Combine)
                objectWillChange.send()
#endif
                return
            } catch {
                if (error as? PartoutError)?.code == .cached {
                    pp_log(ctx, .providers, .info, "VPN infrastructure for \(module.providerId) is up to date")
                    return
                }
                lastError = error
                pp_log(ctx, .providers, .error, "Unable to fetch VPN infrastructure for \(module.providerId): \(error)")
                try Task.checkCancellation()
            }
        }
        if let lastError {
            throw lastError
        }
    }

    public func provider(withId providerId: ProviderID) -> Provider? {
        providers.first {
            $0.id == providerId
        }
    }

    public func presets(for server: ProviderServer, moduleType: ModuleType) async throws -> [ProviderPreset] {
        try await repository.presets(for: server, moduleType: moduleType)
    }

    public func cache(for providerId: ProviderID) -> ProviderCache? {
        cache[providerId]
    }

    public func providerRepository(for module: ProviderModule) async throws -> ProviderRepository {
        if cache(for: module.providerId) == nil {
            try await fetchInfrastructure(for: module)
        }
        return repository.providerRepository(for: module.providerId)
    }

    public func resetCacheForAllProviders() async {
        await repository.resetCache()
    }
}

// MARK: - Observation

private extension APIManager {
    func observeObjects() {
        subscriptions.forEach {
            $0.cancel()
        }
        subscriptions = []

        subscriptions.append(Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            for await providers in repository.indexStream {
                guard !Task.isCancelled else {
                    return
                }
                self.providers = providers
            }
        })

        subscriptions.append(Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            for await cache in repository.cacheStream {
                guard !Task.isCancelled else {
                    return
                }
                self.cache = cache
            }
        })
    }
}
