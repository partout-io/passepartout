// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

/// Contains the necessary info for module handling and serialization.
@available(*, deprecated, message: "Superseded by ModuleType and TaggedModule")
public struct ModuleHandler: Identifiable, Sendable {
    public typealias DecodingBlock = @Sendable (Decoder) throws -> Module

    public typealias LegacyDecodingBlock = @Sendable (JSONDecoder, Data) throws -> Module

    public let id: ModuleType

    public let decoder: DecodingBlock?

    public let legacyDecoder: LegacyDecodingBlock?

    public init<M>(_ id: ModuleType, _ moduleType: M.Type) where M: Module & Decodable {
        self.init(
            id,
            decoder: {
                try M(from: $0)
            },
            legacyDecoder: {
                try $0.decode(moduleType, from: $1)
            }
        )
    }

    public init(
        _ id: ModuleType,
        decoder: DecodingBlock? = nil,
        legacyDecoder: LegacyDecodingBlock? = nil
    ) {
        self.id = id
        self.decoder = decoder
        self.legacyDecoder = legacyDecoder
    }
}

extension ModuleHandler: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
