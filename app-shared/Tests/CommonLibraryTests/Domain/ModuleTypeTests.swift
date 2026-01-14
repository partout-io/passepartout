// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
import Partout
import Testing

struct ModuleTypeTests {
    @Test
    func givenModuleType_whenModuleIsConnectionType_thenIsConnection() {
        #expect(ModuleType.openVPN.isConnection)
        #expect(ModuleType.wireGuard.isConnection)
    }
}
