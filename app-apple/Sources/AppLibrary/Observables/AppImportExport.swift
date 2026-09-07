// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

public struct AppImportExport: Sendable {
    public typealias ConfigBlock = @Sendable () -> Set<ABI.ConfigFlag>

    public typealias ImportProfile = @Sendable (
        _ json: String,
        _ name: String?
    ) throws -> Profile

    public typealias ImportModule = @Sendable (
        _ text: String,
        _ context: ModuleImportContext?
    ) throws -> Module

    public typealias ExportModule = @Sendable (Module) throws -> String

    // ABI proxies
    private let configBlock: ConfigBlock
    private let importProfile: ImportProfile
    private let importModule: ImportModule
    private let exportModule: ExportModule

    // Legacy decoding
    private let legacyRegistry: CodingRegistry

    public init(
        configBlock: @escaping ConfigBlock,
        importProfile: @escaping ImportProfile,
        importModule: @escaping ImportModule,
        exportModule: @escaping ExportModule,
        legacyRegistry: CodingRegistry
    ) {
        self.configBlock = configBlock
        self.importProfile = importProfile
        self.importModule = importModule
        self.exportModule = exportModule
        self.legacyRegistry = legacyRegistry
    }
}

extension AppImportExport {
    public func isEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        configBlock().contains(flag)
    }

    public static let dummy = AppImportExport(
        configBlock: { [] },
        importProfile: { _, _ in .forPreviews },
        importModule: { _, _ in OnDemandModule.Builder().build() },
        exportModule: { _ in "" },
        legacyRegistry: CodingRegistry(registry: Registry(allHandlers: []))
    )

    public func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        let (name, contents) = try input.decodedPair()

        // Try to decode a full Partout profile first
        do {
            return try profile(fromString: contents, name: name)
        } catch {
            pspLog(.core, .debug, "Unable to decode profile for import: \(error)")
        }

        // Fall back to parsing a single module
        do {
            let importedModule: Module
            if isEnabled(.zigCodingImport) {
                let context: ModuleImportContext?
                if let passphrase {
                    context = .OpenVPN(passphrase: passphrase)
                } else {
                    context = nil
                }
                // Via ABI (v3)
                importedModule = try importModule(contents, context)
            } else {
                // Via CodingRegistry (v3)
                importedModule = try legacyRegistry.module(fromContents: contents, object: passphrase)
            }
            return try Profile(withName: name, singleModule: importedModule)
        } catch {
            pspLog(.core, .error, "Unable to import profile module: \(error)")
            throw error
        }
    }

    public func importedModule(from input: ABI.ProfileImporterInput, context: ModuleImportContext?) throws -> Module {
        let (_, contents) = try input.decodedPair()
        return try importModule(contents, context)
    }

    public func exportedModule(from module: Module) throws -> String {
        if isEnabled(.zigCodingExport) {
            return try exportModule(module)
        } else {
            guard let serializable = module as? SerializableModule else {
                throw ABI.AppError.encoding()
            }
            return try serializable.serialized()
        }
    }
}

extension AppImportExport: ProfileCoder {
    public func string(fromProfile profile: Profile) throws -> String {
        if isEnabled(.zigCodingExport) {
            return try ABI.encodeJSON(profile.asTaggedProfile)
        } else {
            // Should be equivalent
            return try legacyRegistry.string(fromProfile: profile)
        }
    }

    public func profile(fromString string: String) throws -> Profile {
        try profile(fromString: string, name: nil)
    }

    public func profile(fromString string: String, name: String?) throws -> Profile {
        if isEnabled(.zigCodingImport) {
            do {
                // Via ABI (v3)
                return try importProfile(string, name)
            } catch {
                // Fall back to legacy decoders (Swift/v3 is tolerant to "Custom Codable")
                return try legacyRegistry.profile(fromString: string)
            }
        } else {
            return try legacyRegistry.profile(fromString: string)
        }
    }
}

extension AppImportExport {
    public nonisolated func json(fromProfile profile: Profile) throws -> String {
        try string(fromProfile: profile)
    }

    public nonisolated func defaultFilename(for profile: Profile) -> String {
        "\(profile.name).json"
    }

    public nonisolated func writeToFile(_ profile: Profile) throws -> String {
        let string = try string(fromProfile: profile)
        let data = Data(string.utf8)
        let filename = "\(profile.id.uuidString).json"
        let path = FileManager.default.makeTemporaryURL(filename: filename).filePath()
        try data.write(toFile: path)
        return path
    }

    public nonisolated func writeToURL(_ profile: Profile) throws -> URL {
        let path = try writeToFile(profile)
        // Make sure to convert to URL to share actual file content
        return URL(fileURLWithPath: path)
    }
}

private extension ABI.ProfileImporterInput {
    func decodedPair() throws -> (name: String, contents: String) {
        let name: String
        let contents: String
        switch self {
        case .contents(let filename, let data):
            name = filename
            contents = try Self.decodeAsTextOrThrow(Data(data.utf8))
        case .file(let url):
            name = url.lastPathComponent
            contents = try Self.decodeAsTextOrThrow(Data(contentsOf: url))
        }
        return (name, contents)
    }

    static func decodeAsTextOrThrow(_ data: Data) throws -> String {
        guard !data.hasBinaryControlBytes, let text = String(data: data, encoding: .utf8) else {
            throw ABI.AppError.binaryFile
        }
        return text
    }
}

extension Profile {
    public init(withName name: String, singleModule: Module) throws {
        let onDemandModule = OnDemandModule.Builder().build()
        var builder = Profile.Builder()
        builder.name = name
        builder.modules = [singleModule, onDemandModule]
        builder.activeModulesIds = Set(builder.modules.map(\.id))
        self = try builder.build()
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
