// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ModuleRegistry {
    public func newModule(ofType moduleType: ModuleType) -> any ModuleBuilder {
        guard var newBuilder = newModuleBuilder(withModuleType: moduleType) else {
            fatalError("Unknown module type: \(self)")
        }
        switch moduleType {
        case .openVPN:
            guard newBuilder is OpenVPNModule.Builder else {
                fatalError("Unexpected module builder type: \(type(of: newBuilder)) != \(self)")
            }
        case .wireGuard:
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
            contents = data
        case .file(let url):
            var encoding: String.Encoding = .utf8
            // XXX: This may be very inefficient
            contents = try String(contentsOf: url, usedEncoding: &encoding)
            name = url.lastPathComponent
        }

        // Try to decode a full Partout profile first
        do {
            return try profile(fromString: contents)
        } catch {
            pspLog(.core, .debug, "Unable to decode profile for import: \(error)")
        }

        // Fall back to parsing a single module
        let importedModule = try module(fromContents: contents, object: passphrase)
        return try Profile(withName: name, singleModule: importedModule)
    }
}
