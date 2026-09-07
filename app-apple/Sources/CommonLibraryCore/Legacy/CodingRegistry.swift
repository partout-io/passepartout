// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@available(*, deprecated)
public final class CodingRegistry {
    public typealias PostDecodeBlock = @Sendable (Profile) -> Profile?

    private let registry: Registry
    private let customModuleHandler: TaggedProfile.CustomModuleHandler?
    private let postDecodeBlock: PostDecodeBlock?

    public init(
        registry: Registry,
        customModuleHandler: TaggedProfile.CustomModuleHandler? = nil
    ) {
        self.registry = registry
        self.customModuleHandler = customModuleHandler
        postDecodeBlock = Self.migratedProfile
    }
}

// MARK: - ProfileCoder

extension CodingRegistry: ProfileCoder {
    public func string(fromProfile profile: Profile) throws -> String {
        try rawStringV3(fromProfile: profile)
    }

    public func profile(fromString string: String) throws -> Profile {
        let decoders: [DecoderPair] = [
            DecoderPair(version: 3, decoder: rawProfileV3),
            DecoderPair(version: 2, decoder: rawProfileLegacyV2),
            DecoderPair(version: 1, decoder: rawProfileLegacyV1)
        ]
        var errors: [String] = []
        for pair in decoders {
            do {
                let parsed = try pair.decoder(string)
                return postDecodeBlock?(parsed) ?? parsed
            } catch {
                errors.append("V\(pair.version): \(error)")
            }
        }
        throw PartoutError(.decoding, errors.joined(separator: ", "))
    }
}

// MARK: Versions and fallback

// Modules as tagged unions, flattened Swift enums
extension CodingRegistry {
    func rawStringV3(fromProfile profile: Profile) throws -> String {
        try ProfileEncoderV3()
            .encode(profile.asTaggedProfile)
    }

    func rawProfileV3(fromString string: String) throws -> Profile {
        try ProfileEncoderV3()
            .decode(string)
            .asProfile(customHandler: customModuleHandler)
    }
}

// Dynamic modules via registry, native Swift enums
extension CodingRegistry {
    func rawStringLegacyV2(fromProfile profile: Profile) throws -> String {
        try LegacyProfileEncoderV2(registry)
            .encode(profile.asCodableProfileV2)
    }

    func rawProfileLegacyV2(fromString string: String) throws -> Profile {
        let codableProfile = try LegacyProfileEncoderV2(registry)
            .decode(string)
        return try Profile(codableProfileV2: codableProfile)
    }
}

// Base64-encoded profile containing Base64-encoded JSON modules (decoding only)
extension CodingRegistry {
    func rawProfileLegacyV1(fromString string: String) throws -> Profile {
        try LegacyDecoderV1().decode(string)
    }
}

private extension CodingRegistry {
    struct DecoderPair {
        let version: Int
        let decoder: (String) throws -> Profile
    }
}

// MARK: Migration

private extension CodingRegistry {
    @Sendable
    static func migratedProfile(_ profile: Profile) -> Profile? {
        do {
            switch profile.version {
            case nil:
                // Set new version at the very least
                let builder = profile.builder(withNewId: false, forUpgrade: true)
                return try builder.build()
            default:
                return nil
            }
        } catch {
            pp_log_id(profile.id, .core, .error, "Unable to migrate profile \(profile.id): \(error)")
            return nil
        }
    }
}

// MARK: - Registry facade

extension CodingRegistry: ConnectionFactory {
    public func connection(for connectionModule: ConnectionModule, parameters: ConnectionParameters) throws -> Connection {
        try registry.connection(for: connectionModule, parameters: parameters)
    }
}

extension CodingRegistry: Resolver {
    public func resolvedProfile(_ profile: Profile) throws -> Profile {
        try registry.resolvedProfile(profile)
    }

    public func resolvedModule(_ module: Module, in profile: Profile?) throws -> Module {
        try registry.resolvedModule(module, in: profile)
    }
}

extension CodingRegistry: ModuleImporter {
    public func module(fromContents contents: String, object: Any?) throws -> Module {
        try registry.module(fromContents: contents, object: object)
    }
}

extension CodingRegistry: ModuleRegistry {
    public func implementation(for moduleType: ModuleType) -> (any ModuleImplementation)? {
        registry.implementation(for: moduleType)
    }
}

// MARK: - Legacy V3

// TaggedProfile/TaggedModule don't need any .userInfo
private final class ProfileEncoderV3 {
    func encode(_ value: TaggedProfile) throws -> String {
        let encoder = JSONEncoder.shared()
        let data = try encoder.encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            throw PartoutError(.encoding, "Not a UTF-8 output")
        }
        return json
    }

    func decode(_ string: String) throws -> TaggedProfile {
        let decoder = JSONDecoder.shared()
        guard let json = string.data(using: .utf8) else {
            throw PartoutError(.decoding, "Not a UTF-8 input")
        }
        return try decoder.decode(TaggedProfile.self, from: json)
    }
}

// MARK: - Legacy V1

private struct LegacyDecoderV1 {
    func decode(_ base64Encoded: String) throws -> Profile {
        guard let data = Data(base64Encoded: base64Encoded) else {
            throw PartoutError(.decoding)
        }
        let encoded = try JSONDecoder.shared().decode(LegacyCodableProfileV1.self, from: data)
        let userInfoMap = try encoded.userInfo.map {
            try JSONSerialization.jsonObject(with: $0)
        }
        let userInfo = try userInfoMap.map {
            try JSON($0)
        }
        let modules = encoded.modules.compactMap { wrapper in
            do {
                return try decodedModule(wrapper)
            } catch {
                pp_log_id(encoded.id, .core, .error, "Unable to decode module: \(error)")
                return nil
            }
        }
        return try Profile.Builder(
            version: encoded.version,
            id: encoded.id,
            name: encoded.name,
            modules: modules,
            activeModulesIds: encoded.activeModulesIds,
            behavior: encoded.behavior,
            userInfo: userInfo
        ).build()
    }

    private func decodedModule(_ wrapper: LegacyModuleWrapperV1) throws -> Module {
        let decoder = JSONDecoder.shared()
        switch wrapper.id {
        case .DNS:
            return try decoder.decode(DNSModule.self, from: wrapper.data)
        case .HTTPProxy:
            return try decoder.decode(HTTPProxyModule.self, from: wrapper.data)
        case .IP:
            return try decoder.decode(IPModule.self, from: wrapper.data)
        case .OnDemand:
            return try decoder.decode(OnDemandModule.self, from: wrapper.data)
        case .OpenVPN:
            return try decoder.decode(OpenVPNModule.self, from: wrapper.data)
        case .WireGuard:
            return try decoder.decode(WireGuardModule.self, from: wrapper.data)
        case .Custom, .Provider, .Undefined:
            throw PartoutError.unknownModuleHandler(moduleType: wrapper.id)
        }
    }
}

private struct LegacyModuleWrapperV1: Decodable {
    let id: ModuleType

    let data: Data
}

private struct LegacyCodableProfileV1: Decodable {
    let version: Int?

    let id: UniqueID

    let name: String

    let modules: [LegacyModuleWrapperV1]

    let activeModulesIds: Set<UniqueID>

    let behavior: ProfileBehavior?

    let userInfo: Data?
}
