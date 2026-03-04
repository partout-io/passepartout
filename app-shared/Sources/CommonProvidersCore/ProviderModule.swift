// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleType {
    public static let provider = ModuleType("Provider")
}

/// A provider-based ``Module``.
public struct ProviderModule: Module, BuildableType, Hashable, Codable {
    public static let moduleHandler = ModuleHandler(.provider, ProviderModule.self)

    public let id: UniqueID

    public let providerId: ProviderID

    public let providerModuleType: ModuleType

    public let authentication: ProviderAuthentication?

    private let moduleOptions: CodableOptions?

    public let entity: ProviderEntity?

    fileprivate init(
        id: UniqueID,
        providerId: ProviderID,
        providerModuleType: ModuleType,
        authentication: ProviderAuthentication?,
        moduleOptions: CodableOptions?,
        entity: ProviderEntity?
    ) {
        self.id = id
        self.providerId = providerId
        self.providerModuleType = providerModuleType
        self.authentication = authentication
        self.moduleOptions = moduleOptions
        self.entity = entity
    }

    public var isFinal: Bool {
        false
    }

    public func options<O>(for moduleType: ModuleType) throws -> O? where O: ProviderOptions {
        try moduleOptions?.options(for: moduleType)
    }

    public func builder() -> Builder {
        Builder(
            id: id,
            providerId: providerId,
            providerModuleType: providerModuleType,
            authentication: authentication,
            moduleOptions: moduleOptions,
            entity: entity
        )
    }
}

extension ProviderModule {
    public struct Builder: ModuleBuilder, Hashable, Sendable {
        public var id: UniqueID

        public var providerId: ProviderID? {
            didSet {
                providerModuleType = nil
            }
        }

        public var providerModuleType: ModuleType? {
            didSet {
                entity = nil
            }
        }

        public var credentials: ProviderAuthentication.Credentials? {
            get {
                authentication?.credentials
            }
            set {
                if authentication == nil {
                    authentication = ProviderAuthentication()
                }
                authentication?.credentials = newValue
            }
        }

        public var token: ProviderAuthentication.Token? {
            get {
                authentication?.token
            }
            set {
                if authentication == nil {
                    authentication = ProviderAuthentication()
                }
                authentication?.token = newValue
            }
        }

        private var authentication: ProviderAuthentication?

        private var moduleOptions: CodableOptions?

        public var entity: ProviderEntity?

        public static func empty() -> Self {
            self.init()
        }

        public init(
            id: UniqueID = UniqueID(),
            providerId: ProviderID? = nil,
            providerModuleType: ModuleType? = nil,
            authentication: ProviderAuthentication? = nil,
            moduleOptions: CodableOptions? = nil,
            entity: ProviderEntity? = nil
        ) {
            self.id = id
            self.providerId = providerId
            self.providerModuleType = providerModuleType
            self.authentication = authentication
            self.moduleOptions = moduleOptions
            self.entity = entity
        }

        public func options<O>(for moduleType: ModuleType) throws -> O? where O: ProviderOptions {
            try moduleOptions?.options(for: moduleType)
        }

        public mutating func setOptions<O>(_ options: O, for moduleType: ModuleType) throws where O: ProviderOptions {
            let encoded = try JSONEncoder().encode(options)
            if moduleOptions == nil {
                moduleOptions = CodableOptions(map: [moduleType: encoded])
            } else {
                moduleOptions?.map[moduleType] = encoded
            }
        }

        public func build() throws -> ProviderModule {
            guard let providerId, let providerModuleType else {
                throw PartoutError(.incompleteModule, self)
            }
            return ProviderModule(
                id: id,
                providerId: providerId,
                providerModuleType: providerModuleType,
                authentication: authentication,
                moduleOptions: moduleOptions,
                entity: entity
            )
        }
    }
}

extension ProviderModule {
    public func checkCompatible(with otherModule: Module, activeIds: Set<UniqueID>) throws {
        precondition(otherModule.id != id)
        if !isMutuallyExclusive {
            return
        }
        guard !(otherModule is Self) else {
            throw PartoutError(.incompatibleModules, [self, otherModule])
        }
        guard (otherModule as? ProviderModule)?.providerModuleType != moduleHandler.id else {
            throw PartoutError(.incompatibleModules, [self, otherModule])
        }
    }
}

// MARK: - Resolver

public protocol ProviderModuleResolver: Sendable {
    var moduleType: ModuleType { get }

    func resolved(from providerModule: ProviderModule) throws -> Module
}

// MARK: - Options

extension ProviderModule {
    public struct CodableOptions: Hashable, Codable, Sendable {
        public var map: [ModuleType: Data]

        public init(map: [ModuleType: Data] = [:]) {
            self.map = map
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                let rawMap = try container.decode([String: Data].self)
                map = rawMap.reduce(into: [:]) {
                    $0[ModuleType($1.key)] = $1.value
                }
            } catch {
                // legacy
                map = try container.decode([ModuleType: Data].self)
            }
        }

        public func encode(to encoder: any Encoder) throws {
            let rawMap: [String: Data] = map.reduce(into: [:]) {
                $0[$1.key.id] = $1.value
            }
            var container = encoder.singleValueContainer()
            try container.encode(rawMap)
        }

        func options<O>(for moduleType: ModuleType) throws -> O? where O: ProviderOptions {
            guard let data = map[moduleType] else {
                return nil
            }
            return try JSONDecoder().decode(O.self, from: data)
        }
    }
}

// MARK: - Shortcuts

extension ProviderModule {
    public init(emptyWithProviderId providerId: ProviderID) throws {

        // requires the two for .build() to succeed
        let moduleType = ModuleType("")
        self = try Builder(providerId: providerId, providerModuleType: moduleType)
            .build()
    }
}
