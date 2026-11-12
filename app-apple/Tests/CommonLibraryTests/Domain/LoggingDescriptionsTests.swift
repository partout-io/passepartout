// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

extension AppErrorLoggingTests {
    struct LoggingDescriptionsTests {
        @Test(arguments: [false, true])
        func profileDescriptionsFollowPrivacy(logsPrivateData: Bool) {
            let previous = PartoutLogger.default
            defer { PartoutLogger.register(previous) }
            var logger = PartoutLogger.Builder()
            logger.logsModules = logsPrivateData
            PartoutLogger.register(logger.build())
            let header = ABI.AppProfileHeader(
                id: UUID(), name: "private-name", moduleTypes: [.OpenVPN],
                primaryModuleType: .OpenVPN, secondaryModuleTypes: [],
                fingerprint: "private-fingerprint", sharingFlags: [.shared], requiredFeatures: [ABI.AppFeature.allCases[0]]
            )
            let event = ABI.ProfileEvent.refresh(.init(headers: [header.id: header]))
            if logsPrivateData {
                for description in [header.description, header.toProto.description, event.description] {
                    #expect(description.contains("private-name"))
                    #expect(description.contains("private-fingerprint"))
                    #expect(description.contains("primaryModuleType"))
                }
                return
            }
            #expect(!event.description.contains("private"))
            #expect(!header.description.contains("private"))
            #expect(header.description.contains(header.id.uuidString))
            #expect(!header.toProto.description.contains("private"))
            for description in [header.description, header.toProto.description] {
                #expect(description.contains("shared"))
                #expect(description.contains(ABI.AppFeature.allCases[0].rawValue))
            }
        }

        @Test(arguments: [false, true])
        func configDescriptionsFollowPrivacy(logsPrivateData: Bool) {
            let previous = PartoutLogger.default
            defer { PartoutLogger.register(previous) }
            var logger = PartoutLogger.Builder()
            logger.logsModules = logsPrivateData
            PartoutLogger.register(logger.build())
            let config = OpenAPIConfigBundleConfig(rate: 100, data: .object(["token": .string("private-token")]))
            let flag = ABI.ConfigFlag.allCases[0]
            let bundle = ConfigBundle(map: [flag: config])
            let event = ABI.ConfigEvent.refresh(.init(flags: [flag], data: [flag: config.data!]))
            if logsPrivateData {
                for description in [config.description, bundle.description, event.description] {
                    #expect(description.contains("private-token"))
                }
                return
            }
            #expect(config.description == "Config(rate=100, minBuild=none, hasData=true)")
            #expect(!bundle.description.contains("private-token"))
            #expect(bundle.description.contains("dataEntries=1"))
            #expect(event.description == "refresh(flags=1, dataEntries=1)")
        }
    }
}
