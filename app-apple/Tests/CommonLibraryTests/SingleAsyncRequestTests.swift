// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryCore
import Partout
import Testing

@MainActor
struct SingleAsyncRequestTests {
    @Test
    func givenInFlightChange_whenToggledAgain_thenLatestLevelWins() async {
        let sut = SingleAsyncRequest()
        var completion: CheckedContinuation<Void, Never>?
        var applied: [DebugLog.Level] = []
        let first = sut.submit {
            await withCheckedContinuation { completion = $0 }
            applied.append(.debug)
        }
        while completion == nil { await Task.yield() }
        sut.submit { Issue.record("Superseded change was sent") }
        let last = sut.submit { applied.append(.info) }
        #expect(applied.isEmpty)
        completion?.resume()
        await first.value
        await last.value
        #expect(applied == [.debug, .info])
    }
}
