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
    func givenInteractiveLogin_whenResolvingConnectionStatus_thenMapsToInstruction() {
        let sut = LocalizedConnectionStatusError(
            lastErrorCode: ABI.AppErrorCode.interactiveLogin.toLastErrorCode
        )

        #expect(sut.localizedDescription == "Open Passepartout to enter the credentials required for this VPN.")
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
            lastErrorCode: PartoutError.Code.wireGuardEmptyPeers.rawValue
        )

        #expect(sut.localizedDescription == "Failed")
    }

    @Test
    func givenUnknownErrorCode_thenFallsBackToGenericDescription() {
        let sut = LocalizedConnectionStatusError(lastErrorCode: "not-a-code")

        #expect(sut.localizedDescription == "Failed")
    }
}
