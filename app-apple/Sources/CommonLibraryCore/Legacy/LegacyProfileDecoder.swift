// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Swift profile formats predating the ABI importer, tried newest first.
public struct LegacyProfileDecoder: Sendable {
    public init() {}

    public func profile(fromString string: String) throws -> Profile {
        let decoders: [(String) throws -> Profile] = [decodeV3, decodeV2, LegacyDecoderV1().decode]
        var errors: [String] = []
        for (index, decode) in decoders.enumerated() {
            do {
                let profile = try decode(string)
                guard profile.version == nil else {
                    return profile
                }
                // Preserve the legacy migration behavior, including the profile ID.
                do {
                    return try profile.builder(withNewId: false, forUpgrade: true).build()
                } catch {
                    pp_log_id(profile.id, .core, .error, "Unable to migrate profile \(profile.id): \(error)")
                    return profile
                }
            } catch {
                errors.append("V\(3 - index): \(error)")
            }
        }
        throw PartoutError(.decoding, errors.joined(separator: ", "))
    }

    private func decodeV3(_ string: String) throws -> Profile {
        try JSONDecoder.shared().decode(TaggedProfile.self, from: Data(string.utf8)).asProfile()
    }

    private func decodeV2(_ string: String) throws -> Profile {
        let encoded = try JSONDecoder().decode(LegacyCodableProfileV2.self, from: Data(string.utf8))
        return try Profile.Builder(
            version: encoded.version,
            id: encoded.id,
            name: encoded.name,
            modules: encoded.modules.map(\.wrappedModule),
            activeModulesIds: encoded.activeModulesIds,
            behavior: encoded.behavior,
            userInfo: encoded.userInfo
        ).build()
    }
}

// MARK: - V2: dynamically typed modules, with native Swift enums

private struct LegacyCodableProfileV2: Decodable {
    let version: Int?
    let id: UniqueID
    let name: String
    let modules: [LegacyCodableModuleV2]
    let activeModulesIds: Set<UniqueID>
    let behavior: ProfileBehavior?
    let userInfo: JSON?
}

private struct LegacyCodableModuleV2: Decodable {
    enum CodingKeys: CodingKey {
        case type
        case payload
        case moduleType
    }

    let wrappedModule: Module

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let moduleType = try container.decodeIfPresent(ModuleType.self, forKey: .type)
            ?? container.decode(ModuleType.self, forKey: .moduleType)
        let payload = try container.contains(.payload) ? container.superDecoder(forKey: .payload) : decoder
        switch moduleType {
        case .DNS:
            wrappedModule = try DNSModule(from: payload)
        case .HTTPProxy:
            wrappedModule = try HTTPProxyModule(from: payload)
        case .IP:
            wrappedModule = try IPModule(from: payload)
        case .OnDemand:
            wrappedModule = try OnDemandModule(from: payload)
        case .OpenVPN:
            wrappedModule = try OpenVPNModule(from: payload)
        case .WireGuard:
            wrappedModule = try WireGuardModule(from: payload)
        case .Custom, .Provider, .Undefined:
            throw PartoutError.unknownModuleHandler(moduleType: moduleType)
        }
    }
}

// MARK: - V1: Base64 profile with Base64 JSON modules

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
