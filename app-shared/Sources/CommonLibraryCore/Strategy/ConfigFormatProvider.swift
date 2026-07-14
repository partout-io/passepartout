// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: - Errors

public enum DeclarativeConfigError: LocalizedError, Sendable {
    case unreadableFile(String, Error)
    case unsupportedFormat(String)
    case parseFailure(String, Error)
    case invalidProfile(String, Error)

    public var errorDescription: String? {
        switch self {
        case .unreadableFile(let path, let error):
            "Unable to read config file at \(path): \(error.localizedDescription)"
        case .unsupportedFormat(let ext):
            "Unsupported config format: \(ext). Supported: json"
        case .parseFailure(let path, let error):
            "Unable to parse config file \(path): \(error.localizedDescription)"
        case .invalidProfile(let name, let error):
            "Invalid profile '\(name)': \(error.localizedDescription)"
        }
    }
}

// MARK: - Provider

public protocol DeclarativeConfigProvider: Sendable {
    func loadConfig(from data: Data) throws -> DeclarativeConfig
}

public struct JSONConfigProvider: DeclarativeConfigProvider {
    public init() {}

    public func loadConfig(from data: Data) throws -> DeclarativeConfig {
        do {
            return try ABI.decode(DeclarativeConfig.self, from: data)
        } catch {
            throw DeclarativeConfigError.parseFailure("(json)", error)
        }
    }
}

public enum ConfigProviderFactory {
    public static func provider(forFileAtPath path: String) throws -> DeclarativeConfigProvider {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        guard ext == "json" else {
            throw DeclarativeConfigError.unsupportedFormat(ext)
        }
        return JSONConfigProvider()
    }
}
