// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
#if PSP_CROSS
        encoder.dateEncodingStrategy = .iso8601
#endif
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
#if PSP_CROSS
        decoder.dateDecodingStrategy = .iso8601
#endif
        return decoder
    }()

    public static func encode<T>(_ value: T) throws -> Data where T: Encodable {
        try encoder.encode(value)
    }

    public static func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try decoder.decode(type, from: data)
    }
}
