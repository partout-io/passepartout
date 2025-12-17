// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension Bundle {
    public func unsafeDecode<T: Decodable>(_ type: T.Type, filename: String) -> T {
        guard let jsonURL = url(forResource: filename, withExtension: "json") else {
            fatalError("Unable to find \(filename).json in bundle")
        }
        do {
            let data = try Data(contentsOf: jsonURL)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            fatalError("Unable to decode \(filename).json: \(error)")
        }
    }
}
