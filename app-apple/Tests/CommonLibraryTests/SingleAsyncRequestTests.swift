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
        let sut = SingleAsyncRequest<Void>()
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
        _ = await first.value
        _ = await last.value
        #expect(applied == [.debug, .info])
    }

    @Test
    func givenPendingRequest_whenReplaced_thenDrainsAndDiscardsPreviousResponse() async {
        let sut = SingleAsyncRequest<[String]>()
        var completion: CheckedContinuation<Void, Never>?
        var started = false
        var replacementSubmitted = false
        let first = Task {
            await sut.fetch {
                await withCheckedContinuation { completion = $0 }
                #expect(Task.isCancelled)
                return ["old"]
            }
        }
        while completion == nil { await Task.yield() }
        let second = Task {
            replacementSubmitted = true
            return await sut.fetch {
                started = true
                return ["new"]
            }
        }
        while !replacementSubmitted { await Task.yield() }
        #expect(!started)
        var latestSubmitted = false
        let latest = Task {
            latestSubmitted = true
            return await sut.fetch { ["latest"] }
        }
        while !latestSubmitted { await Task.yield() }
        completion?.resume()
        #expect(await first.value == nil)
        #expect(await second.value == nil)
        #expect(await latest.value == ["latest"])
        #expect(!started)
    }

    @Test
    func givenActiveRequest_whenCallerCancels_thenDiscardsResponse() async {
        let sut = SingleAsyncRequest<[String]>()
        var completion: CheckedContinuation<Void, Never>?
        let caller = Task {
            await sut.fetch {
                await withCheckedContinuation { completion = $0 }
                #expect(Task.isCancelled)
                return ["old"]
            }
        }
        while completion == nil { await Task.yield() }
        caller.cancel()
        completion?.resume()
        #expect(await caller.value == nil)
        #expect(await sut.fetch { ["next"] } == ["next"])
    }

    @Test
    func givenCancelledCaller_whenFetching_thenDoesNotStartRequest() async {
        let sut = SingleAsyncRequest<[String]>()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await sut.fetch {
                Issue.record("Cancelled caller started a log request")
                return ["unexpected"]
            }
        }
        #expect(await task.value == nil)
    }
}
