// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppABI_C
import Foundation

public protocol DTO: Codable {
    init(json: psp_json) throws
    func encoded() throws -> psp_json
}

extension DTO {
    public init(json: psp_json) throws {
        guard let data = String(cString: json).data(using: .utf8) else {
            throw CancellationError()
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    public func encoded() throws -> psp_json {
        let data = try JSONEncoder().encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw CancellationError()
        }
        return psp_json_new(json)
    }
}

extension Array: DTO where Element: DTO {
}

extension Dictionary: DTO where Key == String, Value: DTO {
}
