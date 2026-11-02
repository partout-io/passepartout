// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibraryCore
import Partout
import Testing

@Suite(.serialized)
struct AppErrorLoggingTests {
    @Test(arguments: [false, true])
    func descriptionsFollowPrivateDataPreference(logsPrivateData: Bool) {
        let previous = PartoutLogger.default
        defer { PartoutLogger.register(previous) }
        var logger = PartoutLogger.Builder()
        logger.logsModules = logsPrivateData
        PartoutLogger.register(logger.build())

        let credentials = OpenVPN.Credentials(username: "private-user", password: "private-password", otpMethod: .none)
        let builder = OpenVPNModule.Builder(credentials: credentials)
        let module = OpenVPNModule(id: builder.id, credentials: credentials)
        let native = PartoutError(.incompleteModule, context: .incompleteModule(builder))
        let malformed = ABI.AppError.malformedModule(builder, reason: native)
        let errors: [ABI.AppError] = [
            malformed, .incompleteModule(builder), .incompatibleModules([module]),
            .moduleRequiresConnection(module), .partout(native), .other(malformed),
            .corruptProviderModule(reason: malformed), .encoding(reason: malformed)
        ]
        for error in errors {
            let erased: Error = error
            for description in ["\(erased)", String(reflecting: erased)] {
                #expect(description.contains("private-user") == logsPrivateData)
                #expect(description.contains("private-password") == logsPrivateData)
                #expect(description.contains(error.code.rawValue))
            }
        }
        if !logsPrivateData {
            #expect("\(malformed)".contains(builder.id.uuidString))
            #expect("\(malformed)".contains("OpenVPN"))
        }
        // Redaction must never remove data retained for the UI.
        guard case .malformedModule(let retained, _) = malformed else {
            Issue.record("Expected malformed module")
            return
        }
        #expect((retained as? OpenVPNModule.Builder)?.credentials == credentials)
    }
}
