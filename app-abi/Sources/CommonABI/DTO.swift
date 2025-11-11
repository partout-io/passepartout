// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonABI_C
import Foundation

public enum DTO {
    public static func decoded<D>(_ json: psp_json) throws -> D where D: Decodable {
        guard let data = String(cString: json).data(using: .utf8) else {
            throw CancellationError()
        }
        return try JSONDecoder().decode(D.self, from: data)
    }
    public static func encoded<E>(_ value: E) throws -> psp_json where E: Encodable {
        let data = try JSONEncoder().encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            throw CancellationError()
        }
        return psp_json_new(json)
    }
}
