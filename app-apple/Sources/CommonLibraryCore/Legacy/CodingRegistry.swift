// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

@available(*, deprecated)
public final class CodingRegistry {
    public typealias PostDecodeBlock = @Sendable (Profile) -> Profile?

    private let customModuleHandler: TaggedProfile.CustomModuleHandler?
    private let postDecodeBlock: PostDecodeBlock?

    public init(
        customModuleHandler: TaggedProfile.CustomModuleHandler? = nil
    ) {
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
            DecoderPair(version: 3, decoder: rawProfileV3)
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
