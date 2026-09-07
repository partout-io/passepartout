// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import Testing

struct LocalizationTests {
    @Test
    func givenUnknownImportedModule_whenDescribing_thenReturnsParsingMessage() {
        let sut = PartoutABIError(.unknownImportedModule)

        #expect(sut.localizedDescription == "Unable to parse.")
    }

    @Test
    func givenWireGuardParseError_whenDescribing_thenReturnsSpecificMessage() throws {
        let info = ParseErrorInfo(
            recognizedType: .WireGuard,
            subCode: WireGuardErrorCode.interfaceHasInvalidAddress.rawValue,
            arguments: ["192.0.2.300/24"]
        )
        let sut = PartoutABIError(.parsing, try JSON(encodable: info))

        #expect(
            sut.localizedDescription ==
                "Address ‘192.0.2.300/24’ is invalid. Interface addresses must be a list of comma-separated IP addresses, optionally in CIDR notation."
        )
    }

    @Test
    func givenOtherError_whenDescribing_thenReturnsDiagnosticMessage() {
        let sut = PartoutABIError(.decoding)

        #expect(sut.localizedDescription == "decoding, payload=null")
    }

    @Test
    func givenOpenVPNPassphraseError_whenConvertingToAppError_thenSpecializesIt() throws {
        let info = ParseErrorInfo(
            recognizedType: .OpenVPN,
            subCode: OpenVPNErrorCode.passphraseRequired.rawValue,
            arguments: []
        )
        let sut = ABI.AppError(
            PartoutABIError(.parsing, try JSON(encodable: info))
        )

        guard case .openVPNPassphraseRequired = sut else {
            Issue.record("Expected openVPNPassphraseRequired, got \(sut)")
            return
        }
    }
}
