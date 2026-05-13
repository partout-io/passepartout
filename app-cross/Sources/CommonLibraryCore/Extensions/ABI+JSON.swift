// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public static func encode<T>(_ value: T) throws -> Data where T: Encodable {
        try JSONEncoder.new().encode(value)
    }

    public static func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        try JSONDecoder.new().decode(type, from: data)
    }
}
