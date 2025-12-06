// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_CROSS
import CommonProvidersAPI
import CommonProvidersCore
#endif
import Partout

public final class DefaultAPIMapper: APIMapper {
    private let ctx: PartoutLoggerContext

    private let baseURL: URL

    private let timeout: TimeInterval

    private let api: ProviderScriptingAPI

    private let engineFactory: @Sendable (ProviderScriptingAPI) -> ScriptingEngine

    public init(
        _ ctx: PartoutLoggerContext,
        baseURL: URL,
        timeout: TimeInterval = 10.0,
        api: ProviderScriptingAPI,
        engineFactory: @escaping @Sendable (ProviderScriptingAPI) -> ScriptingEngine
    ) {
        self.ctx = ctx
        self.baseURL = baseURL
        self.timeout = timeout
        self.api = api
        self.engineFactory = engineFactory
    }

    public func index() async throws -> [Provider] {
        let data = try await data(for: .index)
        let json = try JSONDecoder().decode(API.REST.Index.self, from: data)

        return json
            .providers
            .map {
                let metadata = $0.metadata.reduce(into: [:]) {
                    $0[ModuleType($1.key)] = Provider.Metadata(userInfo: $1.value)
                }
                return Provider(
                    $0.id.rawValue,
                    description: $0.description,
                    metadata: metadata
                )
            }
    }

    public func authenticate(_ module: ProviderModule, on deviceId: String) async throws -> ProviderModule {

        // preconditions (also check in script)
        guard let auth = module.authentication, !auth.isEmpty else {
            throw PartoutError(.authentication)
        }
        guard let storage: WireGuardProviderStorage = try module.options(for: .wireGuard) else {
            throw PartoutError(.Providers.missingOption)
        }
        guard storage.sessions?[deviceId] != nil else {
            throw PartoutError(.Providers.missingOption)
        }

        let library = try await scriptLibrary(at: .provider(module.providerId))
        let engine = engineFactory(api)
        return try await engine.authenticate(ctx, module, on: deviceId, with: library)
    }

    public func infrastructure(for module: ProviderModule, cache: ProviderCache?) async throws -> ProviderInfrastructure {
        let library = try await scriptLibrary(at: .provider(module.providerId))
        let engine = engineFactory(api)
        return try await engine.infrastructure(ctx, module, with: library, cache: cache)
    }
}

// MARK: - Engine

// TODO: #54/partout, assumes engine to be JavaScript
extension ScriptingEngine {
    func authenticate(_ ctx: PartoutLoggerContext, _ module: ProviderModule, on deviceId: String, with library: String) async throws -> ProviderModule {
        let script = try scriptCall(ctx, withName: "authenticate", args: [
            module.stripped(),
            deviceId
        ])
        let result = try await execute(
            script,
            after: library,
            returning: ScriptResult<ProviderModule>.self
        )
        if let error = result.error {
            throw PartoutError(.scriptException, error)
        }
        guard let response = result.response else {
            throw PartoutError(.scriptException, result.error ?? "unknown")
        }
        return response
    }

    func infrastructure(_ ctx: PartoutLoggerContext, _ module: ProviderModule, with library: String, cache: ProviderCache?) async throws -> ProviderInfrastructure {
        var headers: [String: String] = [:]
        if let lastUpdate = cache?.lastUpdate {
            headers["If-Modified-Since"] = lastUpdate.toRFC1123()
        }
        if let tag = cache?.tag {
            headers["If-None-Match"] = tag
        }
        let script = try scriptCall(ctx, withName: "getInfrastructure", args: [
            module.stripped(),
            headers,
            true
        ])
        let result = try await execute(
            script,
            after: library,
            returning: ScriptResult<ProviderInfrastructure>.self
        )
        guard let response = result.response else {
            if let error = result.error {
                throw PartoutError(.scriptException, error)
            }
            // XXX: empty response without error = cached response
            else {
                throw PartoutError(.cached)
            }
        }
        return response
    }

    func scriptCall(_ ctx: PartoutLoggerContext, withName name: String, args: [Any]) throws -> String {
        let argsString = try args
            .map {
                if let value = $0 as? String {
                    return "'\(value)'"
                } else if let value = $0 as? Int {
                    return value.description
                } else if let value = $0 as? Bool {
                    return value.description
                } else if let value = $0 as? Encodable {
                    let encoded = try JSONEncoder().encode(value)
                    guard let json = String(data: encoded, encoding: .utf8) else {
                        throw PartoutError(.encoding)
                    }
//                    pp_log(ctx, .api, .debug, "Argument: \(json)")
//                    pp_log(ctx, .api, .debug, "Argument (escaped): \(json.jsEscaped)")
                    return "JSON.parse('\(json.jsEscaped)')"
                } else {
                    assertionFailure("Unhandled argument type")
                    return "null"
                }
            }
            .joined(separator: ",")

        return "JSON.stringify(\(name)(\(argsString)))"
    }
}

// MARK: - Helpers

private extension ProviderModule {

    // save heavy encoding of unused .entity
    func stripped() throws -> Self {
        var stripped = builder()
        stripped.entity = nil
        return try stripped.build()
    }
}

private extension String {
    var jsEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

extension DefaultAPIMapper {
    func scriptLibrary(at resource: API.REST.Resource) async throws -> String {
        let data = try await data(for: resource)
        guard let script = String(data: data, encoding: .utf8) else {
            throw PartoutError(.notFound)
        }
        return script
    }

    func data(for resource: API.REST.Resource) async throws -> Data {
        let url = baseURL.miniAppending(path: resource.path)
        pp_log(ctx, .providers, .info, "Fetch data for \(resource): \(url)")
        let cfg: URLSessionConfiguration = .default
        cfg.requestCachePolicy = .reloadRevalidatingCacheData
        cfg.urlCache = .shared
        cfg.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: cfg)
        let request = URLRequest(url: url)
        do {
            let result = try await session.data(for: request)
            if URLCache.shared.cachedResponse(for: request) != nil {
                pp_log(ctx, .providers, .info, "Data was cached: \(url)")
            }
            return result.0
        } catch {
            pp_log(ctx, .providers, .error, "Unable to fetch data: \(url), \(error)")
            throw error
        }
    }
}

// JS -> Swift
private struct ScriptResult<T>: Decodable where T: Decodable {
    let response: T?

    let error: String?
}
