// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import AppLibrary
import CommonLibrary
import Partout
import Testing

struct ConnectionStatusErrorTests {
    @Test
    func givenAppErrorCodeWithConnectionStatus_thenMapsToLocalizedDescription() {
        let sut = LocalizedConnectionStatusError(
            lastErrorCode: ABI.AppErrorCode.ineligibleProfile.toLastErrorCode
        )

        #expect(sut.localizedDescription == "Purchase required")
    }

    @Test
    func givenAppErrorCodeWithoutConnectionStatus_thenFallsBackToGenericDescription() {
        let sut = LocalizedConnectionStatusError(
            lastErrorCode: ABI.AppErrorCode.timeout.toLastErrorCode
        )

        #expect(sut.localizedDescription == "Failed")
    }

    @Test
    func givenPartoutErrorCodeWithConnectionStatus_thenMapsToLocalizedDescription() {
        let sut = LocalizedConnectionStatusError(
            lastErrorCode: PartoutError.Code.timeout.rawValue
        )

        #expect(sut.localizedDescription == "Timeout")
    }

    @Test
    func givenPartoutErrorCodeWithoutConnectionStatus_thenFallsBackToGenericDescription() {
        let sut = LocalizedConnectionStatusError(
            lastErrorCode: PartoutErrorPair.wireGuard(.emptyPeers).rawValue
        )

        #expect(sut.localizedDescription == "Failed")
    }

    @Test
    func givenProtocolCode_whenDescribing_thenUsesSubCode() {
        let sut = LocalizedConnectionStatusError(lastErrorCode: PartoutErrorPair.openVPN(.tlsFailure).rawValue)
        #expect(sut.localizedDescription == OpenVPNErrorCode.tlsFailure.localizedConnectionDescription)
    }

    @Test(arguments: [
        PartoutErrorPair(code: .openVPN, subCode: "unknown").rawValue,
        PartoutErrorPair(code: .wireGuard, subCode: "unknown").rawValue,
        PartoutErrorCode.openVPN.rawValue,
        PartoutErrorPair(code: .openVPN, subCode: "").rawValue
    ])
    func givenUnknownSubCode_whenDescribing_thenFallsBack(raw: String) {
        #expect(LocalizedConnectionStatusError(lastErrorCode: raw).localizedDescription == "Failed")
    }

    @Test
    func givenUnknownErrorCode_thenFallsBackToGenericDescription() {
        let sut = LocalizedConnectionStatusError(lastErrorCode: "not-a-code")

        #expect(sut.localizedDescription == "Failed")
    }
}
