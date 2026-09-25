// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Foundation
import Testing

struct AppImportExportTests {
    @Test(arguments: [1, 2, 3])
    func givenLegacyProfile_whenDecode_thenPreservesKnownModules(version: Int) throws {
        for module in try newKnownModules() {
            var builder = Profile.Builder(name: "legacy", modules: [module])
            builder.activeModulesIds = [module.id]
            builder.userInfo = .object(["source": .string("legacy")])
            let profile = try builder.build()
            let encoded = try legacyString(profile, version: version)

            let decoded = try AppImportExport.dummy.profile(fromString: encoded)

            #expect(decoded == profile)
            #expect(decoded.modules.first?.moduleType == module.moduleType)
            #expect(String(reflecting: type(of: decoded.modules[0])) == String(reflecting: type(of: module)))
        }
    }

    @Test
    func givenFlattenedV2Profile_whenDecode_thenPreservesModules() throws {
        let profile = try Profile.Builder(name: "flattened", modules: Array(newKnownModules().dropLast())).build()
        var object = try #require(JSONSerialization.jsonObject(
            with: Data(legacyString(profile, version: 2).utf8)
        ) as? [String: Any])
        let modules = try #require(object["modules"] as? [[String: Any]])
        object["modules"] = try modules.map { module in
            var payload = try #require(module["payload"] as? [String: Any])
            payload["type"] = module["moduleType"]
            return payload
        }
        let encoded = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
        let decoded = try AppImportExport.dummy.profile(fromString: encoded)
        #expect(decoded == profile)
    }

    @Test
    func givenUnversionedProfile_whenDecode_thenUpgradesWithoutChangingID() throws {
        let profile = try Profile.Builder(name: "unversioned").build()
        var object = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder.shared().encode(profile.asTaggedProfile)
        ) as? [String: Any])
        object.removeValue(forKey: "version")
        let encoded = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)

        let decoded = try AppImportExport.dummy.profile(fromString: encoded)

        #expect(decoded.id == profile.id)
        #expect(decoded.version == Profile.Builder.currentVersion)
    }

    @Test
    func givenCurrentProfile_whenRoundTrip_thenPreservesProfile() throws {
        let profile = try Profile.Builder(name: "current", modules: Array(newKnownModules().dropLast())).build()
        let sut = AppImportExport.dummy
        let decoded = try sut.profile(fromString: sut.string(fromProfile: profile))
        #expect(decoded == profile)
    }

    @Test
    func givenInvalidProfile_whenLegacyDecodingFails_thenThrowsABIFallbackError() {
        #expect(throws: ABI.AppError.self) {
            try AppImportExport.dummy.profile(fromString: "invalid")
        }
    }

    @Test
    func givenModule_whenExport_thenUsesABIExporter() throws {
        let sut = AppImportExport(
            configBlock: { [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "exported" }
        )

        let encoded = try sut.exportedModule(from: OnDemandModule.Builder().build())

        #expect(encoded == "exported")
    }

    @Test
    func givenBinaryFile_whenImportProfile_thenThrowsBinaryFile() throws {
        let sut = AppImportExport(
            configBlock: { [] },
            importModule: { _, _ in throw ABI.AppError.importError() },
            exportModule: { _ in "" }
        )
        let url = URL.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension("bin")
        try Data([0x00, 0x01, 0x02, 0x03]).write(to: url)
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        var didThrowBinaryFile = false
        do {
            _ = try sut.importedProfile(from: .file(url), passphrase: nil)
        } catch ABI.AppError.binaryFile {
            didThrowBinaryFile = true
        } catch {
            throw error
        }
        #expect(didThrowBinaryFile)
    }
}

private extension AppImportExportTests {
    func legacyString(_ profile: Profile, version: Int) throws -> String {
        if version == 3 {
            return try JSONEncoder.shared().encodeJSON(profile.asTaggedProfile)
        }
        let encoder = JSONEncoder(userInfo: [.legacySwiftEncoding: true])
        var object = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder.shared().encode(profile.asTaggedProfile)
        ) as? [String: Any])
        object["modules"] = try profile.modules.map { module -> [String: Any] in
            let encodable = try #require(module as? any Encodable)
            let data = try encoder.encode(encodable)
            if version == 1 {
                return ["id": module.moduleType.rawValue, "data": data.base64EncodedString()]
            }
            return ["moduleType": module.moduleType.rawValue,
                    "payload": try JSONSerialization.jsonObject(with: data)]
        }
        if version == 1 {
            object["userInfo"] = try profile.userInfo.map {
                try JSONEncoder.shared().encode($0).base64EncodedString()
            }
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        return version == 1 ? data.base64EncodedString() : String(decoding: data, as: UTF8.self)
    }

    func newKnownModules() throws -> [Module] {
        let dnsModule = try DNSModule.Builder(servers: ["1.1.1.1"]).build()
        let ipModule = IPModule.Builder(mtu: 1280).build()
        let httpProxyModule = try HTTPProxyModule.Builder(
            address: "1.1.1.1",
            port: 8080
        ).build()
        let onDemandModule = OnDemandModule.Builder().build()
        var openVPNConfiguration = OpenVPN.Configuration.Builder()
        openVPNConfiguration.ca = OpenVPN.CryptoContainer(pem: "ca is required")
        openVPNConfiguration.cipher = .aes128cbc
        openVPNConfiguration.remotes = [
            try ExtendedEndpoint("vpn.example.com", EndpointProtocol(.tcp, 443))
        ]
        let openVPNModule = try OpenVPNModule.Builder(
            configurationBuilder: openVPNConfiguration
        ).build()
        var wireGuardConfiguration = WireGuard.Configuration.Builder(privateKey: "")
        wireGuardConfiguration.peers = [WireGuard.RemoteInterface.Builder(publicKey: "")]
        let wireGuardModule = try WireGuardModule.Builder(
            configurationBuilder: wireGuardConfiguration
        ).build()
        return [
            dnsModule,
            httpProxyModule,
            ipModule,
            onDemandModule,
            openVPNModule,
            wireGuardModule
        ]
    }
}
