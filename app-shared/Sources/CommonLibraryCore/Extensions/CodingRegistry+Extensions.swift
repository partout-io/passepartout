// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleRegistry {
    public func newModule(ofType moduleType: ModuleType) -> any ModuleBuilder {
        guard var newBuilder = moduleType.builderType?.empty() else {
            fatalError("Unknown module type: \(self)")
        }
        switch moduleType {
        case .OpenVPN:
            guard newBuilder is OpenVPNModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
        case .WireGuard:
            guard var builder = newBuilder as? WireGuardModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
            guard let impl = implementation(for: builder.moduleType) as? WireGuardModule.Implementation else {
                fatalError("Missing WireGuard implementation for module creation")
            }
            builder.configurationBuilder = WireGuard.Configuration.Builder(keyGenerator: impl.keyGenerator)
            newBuilder = builder
        default:
            break
        }
        return newBuilder
    }
}

extension CodingRegistry {
    public func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        let name: String
        let contents: String
        switch input {
        case .contents(let filename, let data):
            name = filename
            contents = try Self.decodeAsTextOrThrow(Data(data.utf8))
        case .file(let url):
            name = url.lastPathComponent
            contents = try Self.decodeAsTextOrThrow(Data(contentsOf: url))
        }

        // Try to decode a full Partout profile first
        do {
            return try profile(fromString: contents)
        } catch {
            pspLog(.core, .debug, "Unable to decode profile for import: \(error)")
        }

        // Fall back to parsing a single module
        do {
            let importedModule = try module(fromContents: contents, object: passphrase)
            return try Profile(withName: name, singleModule: importedModule)
        } catch {
            pspLog(.core, .error, "Unable to import profile module: \(error)")
            throw error
        }
    }
}

private extension CodingRegistry {
    static func decodeAsTextOrThrow(_ data: Data) throws -> String {
        guard !data.hasBinaryControlBytes, let text = String(data: data, encoding: .utf8) else {
            throw ABI.AppError.binaryFile
        }
        return text
    }
}

private extension Data {
    var hasBinaryControlBytes: Bool {
        guard !isEmpty else {
            return false
        }
        var controlCount = 0
        for byte in self {
            if byte == 0 {
                return true
            }
            if byte < Self.asciiSpace && !Self.textControlBytes.contains(byte) {
                controlCount += 1
            }
        }
        return controlCount > 0 && controlCount * 100 > count
    }

    static let textControlBytes: Set<UInt8> = [
        0x09,
        0x0A,
        0x0D,
        0x0C
    ]

    static let asciiSpace: UInt8 = 0x20
}

private extension ModuleType {
    var builderType: (any ModuleBuilder.Type)? {
        switch self {
        case .DNS:
            return DNSModule.Builder.self
        case .HTTPProxy:
            return HTTPProxyModule.Builder.self
        case .IP:
            return IPModule.Builder.self
        case .OnDemand:
            return OnDemandModule.Builder.self
        case .OpenVPN:
            return OpenVPNModule.Builder.self
        case .Provider:
            return ProviderModule.Builder.self
        case .WireGuard:
            return WireGuardModule.Builder.self
        default:
            assertionFailure("ModuleType '\(rawValue)' has no ModuleBuilder associated")
            return nil
        }
    }
}
