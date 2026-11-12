// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

struct LoggingDescriptionsTests {
    @Test
    func givenProfileHeader_whenDescribed_thenOmitsNameAndFingerprint() {
        let header = ABI.AppProfileHeader(
            id: UUID(), name: "private-name", moduleTypes: [.OpenVPN],
            primaryModuleType: .OpenVPN, secondaryModuleTypes: [],
            fingerprint: "private-fingerprint", sharingFlags: [.shared], requiredFeatures: [ABI.AppFeature.allCases[0]]
        )
        #expect(!header.description.contains("private"))
        #expect(header.description.contains(header.id.uuidString))
        #expect(!header.toProto.description.contains("private"))
        for description in [header.description, header.toProto.description] {
            #expect(description.contains("shared"))
            #expect(description.contains(ABI.AppFeature.allCases[0].rawValue))
        }
    }

    @Test
    func givenConfigPayload_whenDescribed_thenOmitsArbitraryData() {
        let config = OpenAPIConfigBundleConfig(rate: 100, data: .object(["token": .string("private-token")]))
        #expect(config.description == "Config(rate=100, minBuild=none, hasData=true)")
        let flag = ABI.ConfigFlag.allCases[0]
        let bundle = ConfigBundle(map: [flag: config])
        #expect(!bundle.description.contains("private-token"))
        #expect(bundle.description.contains("dataEntries=1"))
        let event = ABI.ConfigEvent.refresh(.init(flags: [flag], data: [flag: config.data!]))
        #expect(event.description == "refresh(flags=1, dataEntries=1)")
    }
}
