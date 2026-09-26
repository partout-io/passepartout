// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary
import Testing

struct LocalizationTests {
    @Test
    func givenNativeValidationError_whenConverting_thenPreservesField() {
        let sut = ABI.AppError(PartoutError.invalidField(.DNS.ipDomains))
        guard case .invalidField(let key) = sut else {
            Issue.record("Expected invalidField")
            return
        }
        #expect(key == "errors.modules.\(PartoutError.ModuleField.DNS.ipDomains.key)")
    }

    @Test
    func givenPortableIncompleteModule_whenConverting_thenPreservesError() {
        let error = PartoutError(.incompleteModule, payload: ["moduleId": "example"])
        let sut = ABI.AppError(error)
        guard case .partout(let wrapped) = sut else {
            Issue.record("Expected portable error without a native builder")
            return
        }
        #expect(wrapped.payload == error.payload)
    }


    @Test
    func givenUnknownImportedModule_whenDescribing_thenReturnsParsingMessage() {
        let sut = ABI.AppError(PartoutError(.unknownImportedModule))

        #expect(sut.localizedDescription(style: .errorHandler) == "Unable to parse.")
    }

    @Test
    func givenWireGuardParseError_whenDescribing_thenReturnsSpecificMessage() throws {
        let info = ParseErrorInfo(
            recognizedType: .WireGuard,
            subCode: WireGuardErrorCode.interfaceHasInvalidAddress.rawValue,
            arguments: ["192.0.2.300/24"]
        )
        let sut = ABI.AppError(PartoutError(.parsing, payload: try JSON(encodable: info)))

        #expect(
            sut.localizedDescription(style: .errorHandler) ==
                "Address ‘192.0.2.300/24’ is invalid. Interface addresses must be a list of comma-separated IP addresses, optionally in CIDR notation."
        )
    }

    @Test(
        arguments: [PartoutErrorCode.keychainAddItem, .keychainItemNotFound, .invalidValue, .decoding],
        [nil, JSON.string("diagnostic details")]
    )
    func givenOtherError_whenDescribing_thenReturnsLocalizedFallback(code: PartoutErrorCode, payload: JSON?) {
        let sut = ABI.AppError(PartoutError(code, payload: payload))

        #expect(sut.localizedDescription(style: .errorHandler) == Strings.Errors.App.partout(code.rawValue))
    }

    @Test(arguments: [OpenVPNErrorCode.passphraseRequired, .unableToDecrypt])
    func givenOpenVPNPassphraseError_whenConvertingToAppError_thenPreservesIt(code: OpenVPNErrorCode) throws {
        let info = ParseErrorInfo(
            recognizedType: .OpenVPN,
            subCode: code.rawValue,
            arguments: []
        )
        let error = PartoutError(.parsing, payload: try JSON(encodable: info))
        let sut = ABI.AppError(error)

        guard case .partout(let wrapped) = sut else {
            Issue.record("Expected PartoutError, got \(sut)")
            return
        }
        #expect(wrapped.payload == error.payload)
        #expect(wrapped.isOpenVPNPassphraseRequired)
        #expect(sut.code == .partout)
        #expect(sut.localizedDescription(style: .errorHandler) == Strings.Errors.App.other)
    }

    @Test
    func givenOpenVPNCompressionParseError_whenDescribing_thenUsesSpecificMessage() throws {
        let info = ParseErrorInfo(
            recognizedType: .OpenVPN,
            subCode: OpenVPNErrorCode.unsupportedCompression.rawValue,
            arguments: ["lzo"]
        )
        let error = PartoutError(.parsing, payload: try JSON(encodable: info))
        #expect(ABI.AppError(error).localizedDescription(style: .errorHandler) == Strings.Errors.Openvpn.unsupportedCompression)
    }

    @Test(arguments: [nil, JSON.string("unexpected payload"), JSON.object([:])])
    func givenMissingOrMalformedParseInfo_whenDescribing_thenFallsBack(payload: JSON?) {
        let error = PartoutError(.parsing, payload: payload)
        #expect(!error.isOpenVPNPassphraseRequired)
        #expect(ABI.AppError(error).localizedDescription(style: .errorHandler) == Strings.Errors.App.parsing)
    }

    @Test
    func givenRuntimeError_whenReadingParseInfo_thenReturnsNil() throws {
        let info = ParseErrorInfo(
            recognizedType: .OpenVPN,
            subCode: OpenVPNErrorCode.passphraseRequired.rawValue,
            arguments: []
        )
        let error = PartoutError(.openVPN, payload: try JSON(encodable: info))
        #expect(error.parseErrorInfo == nil)
        #expect(!error.isOpenVPNPassphraseRequired)
    }

    @Test
    func givenProtocolErrors_whenDescribing_thenUsesPartoutLocalization() {
        let compression = PartoutError(codeForOpenVPN: .unsupportedCompression)
        let emptyPeers = PartoutError(codeForWireGuard: .emptyPeers)

        #expect(!compression.isOpenVPNPassphraseRequired)
        #expect(!emptyPeers.isOpenVPNPassphraseRequired)
        #expect(ABI.AppError(compression).code == .partout)
        #expect(ABI.AppError(emptyPeers).code == .partout)
        #expect(ABI.AppError(compression).localizedDescription(style: .errorHandler) ==
            "OpenVPN compression is unsafe and no longer supported.")
        #expect(ABI.AppError(emptyPeers).localizedDescription(style: .errorHandler) == "No peers defined.")
    }
}
