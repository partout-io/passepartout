// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryApple
import Partout
import Testing

@MainActor
struct TunnelLogLevelRequestTests {
    @Test
    func givenInFlightChange_whenToggledAgain_thenLatestLevelWins() async {
        let sut = TunnelLogLevelRequest()
        var completion: CheckedContinuation<Void, Never>?
        var applied: [DebugLog.Level] = []
        let first = sut.submit(.debug) { level in
            await withCheckedContinuation { completion = $0 }
            applied.append(level)
        }
        while completion == nil { await Task.yield() }
        sut.submit(.debug) { _ in Issue.record("Superseded change was sent") }
        let last = sut.submit(.info) { applied.append($0) }
        #expect(applied.isEmpty)
        completion?.resume()
        await first.value
        await last.value
        #expect(applied == [.debug, .info])
    }
}
