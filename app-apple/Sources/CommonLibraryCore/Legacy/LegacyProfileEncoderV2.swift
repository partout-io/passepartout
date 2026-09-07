// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@available(*, deprecated)
final class LegacyProfileEncoderV2 {
    private let registry: Registry

    init(_ registry: Registry) {
        self.registry = registry
    }

    func encode(_ value: LegacyCodableProfileV2) throws -> String {
        let encoder = JSONEncoder(userInfo: [.legacySwiftEncoding: true])
        let data = try encoder.encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            throw PartoutError(.encoding, "Not a UTF-8 output")
        }
        return json
    }

    func decode(_ string: String) throws -> LegacyCodableProfileV2 {
        let decoder = JSONDecoder(userInfo: [.moduleDecoder: registry])
        guard let json = string.data(using: .utf8) else {
            throw PartoutError(.decoding, "Not a UTF-8 input")
        }
        return try decoder.decode(LegacyCodableProfileV2.self, from: json)
    }
}

@available(*, deprecated)
public struct LegacyCodableProfileV2: ProfileType, Codable, Sendable {
    public let version: Int?

    public let id: UniqueID

    public let name: String

    public let modules: [LegacyCodableModuleV2]

    public let activeModulesIds: Set<UniqueID>

    public let behavior: ProfileBehavior?

    public let userInfo: JSON?
}

@available(*, deprecated)
public struct LegacyCodableModuleV2: Codable, Sendable {
    enum CodingKeys: CodingKey {
        case type
        case payload
        case moduleType
    }

    let moduleType: ModuleType

    let wrappedModule: Module

    init(wrappedModule: Module) {
        moduleType = wrappedModule.moduleType
        self.wrappedModule = wrappedModule
    }

    public init(from decoder: Decoder) throws {
        guard let moduleDecoder = decoder.userInfo[.moduleDecoder] as? LegacyModuleDecoder else {
            throw PartoutError(.decoding, "Missing module decoder from .userInfo")
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        moduleType = try container.decodeIfPresent(ModuleType.self, forKey: .type)
            ?? container.decode(ModuleType.self, forKey: .moduleType)
        let module: Module
        // Legacy Swift encoding
        if container.contains(.payload) {
            let payloadDecoder = try container.superDecoder(forKey: .payload)
            module = try moduleDecoder.decodedModule(from: payloadDecoder, ofType: moduleType)
        } else {
            module = try moduleDecoder.decodedModule(from: decoder, ofType: moduleType)
        }
        assert(module.moduleType == moduleType, "Deserialized type mismatch")
        wrappedModule = module
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        guard let encodableModule = wrappedModule as? Encodable else {
            throw PartoutError(.encoding, "Module not encodable")
        }
        // Legacy Swift encoding
        if encoder.userInfo.usesLegacySwiftEncoding {
            try container.encode(moduleType, forKey: .moduleType)
            try container.encode(encodableModule, forKey: .payload)
            return
        }
        try container.encode(moduleType, forKey: .type)
        try encodableModule.encode(to: encoder)
    }
}

@available(*, deprecated)
extension Profile {
    init(codableProfileV2 codableProfile: LegacyCodableProfileV2) throws {
        self = try Profile.Builder(
            version: codableProfile.version,
            id: codableProfile.id,
            name: codableProfile.name,
            modules: codableProfile.modules.map(\.wrappedModule),
            activeModulesIds: codableProfile.activeModulesIds,
            behavior: codableProfile.behavior,
            userInfo: codableProfile.userInfo
        ).build()
    }

    var asCodableProfileV2: LegacyCodableProfileV2 {
        LegacyCodableProfileV2(
            version: Profile.Builder.currentVersion,
            id: id,
            name: name,
            modules: modules.map {
                LegacyCodableModuleV2(wrappedModule: $0)
            },
            activeModulesIds: activeModulesIds,
            behavior: behavior,
            userInfo: userInfo
        )
    }
}

extension Registry: LegacyModuleDecoder {
    public func decodedModule(from decoder: Decoder, ofType moduleType: ModuleType) throws -> Module {
        guard let handler = handler(withId: moduleType) else {
            throw PartoutError(.unknownModuleHandler)
        }
        guard let handlerDecoder = handler.decoder else {
            throw PartoutError(.decoding, "Missing decoder")
        }
        return try handlerDecoder(decoder)
    }
}
