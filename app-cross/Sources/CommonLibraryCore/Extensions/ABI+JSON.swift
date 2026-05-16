// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public static func encode<T>(_ value: T) throws -> Data where T: Encodable {
        try JSONEncoder.shared().encode(value)
    }

    public static func encodeJSON<T>(_ value: T) throws -> String where T: Encodable {
        do {
            let data = try encode(value)
            guard let json = String(data: data, encoding: .utf8) else {
                throw ABI.AppError.encoding()
            }
            return json
        } catch {
            throw ABI.AppError.encoding(reason: error)
        }
    }

    public static func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try JSONDecoder.shared().decode(type, from: data)
    }
}
