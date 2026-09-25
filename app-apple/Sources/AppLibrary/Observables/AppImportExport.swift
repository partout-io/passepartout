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

    private let legacyDecoder = LegacyProfileDecoder()

    // ABI proxies
    private let configBlock: ConfigBlock
    private let importModule: ImportModule
    private let exportModule: ExportModule

    public init(
        configBlock: @escaping ConfigBlock,
        importModule: @escaping ImportModule,
        exportModule: @escaping ExportModule
    ) {
        self.configBlock = configBlock
        self.importModule = importModule
        self.exportModule = exportModule
    }
}

extension AppImportExport {
    public func isEnabled(_ flag: ABI.ConfigFlag) -> Bool {
        configBlock().contains(flag)
    }

    public static let dummy = AppImportExport(
        configBlock: { [] },
        importModule: { _, _ in OnDemandModule.Builder().build() },
        exportModule: { _ in "" }
    )

    public func importedProfile(from input: ABI.ProfileImporterInput, passphrase: String?) throws -> Profile {
        let (name, contents) = try input.decodedPair()

        // Try to decode a full Partout profile first
        do {
            return try profile(fromString: contents)
        } catch {
            pspLog(.core, .debug, "Unable to decode profile for import: \(error)")
        }

        // Fall back to parsing a single module
        do {
            let context: ModuleImportContext?
            if let passphrase {
                context = .OpenVPN(passphrase: passphrase)
            } else {
                context = nil
            }
            let importedModule = try importModule(contents, context)
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
        try exportModule(module)
    }
}

extension AppImportExport: ProfileCoder {
    public func string(fromProfile profile: Profile) throws -> String {
        try ABI.encodeJSON(profile.asTaggedProfile)
    }

    public func profile(fromString string: String) throws -> Profile {
        if let profile = try? legacyDecoder.profile(fromString: string) {
            return profile
        }
        return try ABI.decodeJSON(TaggedProfile.self, from: string).asProfile()
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
        let path = FileManager.default.temporaryDirectory
            .appending(component: filename)
            .filePath()
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
