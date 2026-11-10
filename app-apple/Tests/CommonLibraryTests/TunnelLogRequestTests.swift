// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibraryApple
import Testing

@MainActor
struct TunnelLogRequestTests {
    @Test
    func givenPendingRequest_whenReplaced_thenDrainsAndDiscardsPreviousResponse() async {
        let sut = TunnelLogRequest()
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
        #expect(await first.value == [])
        #expect(await second.value == [])
        #expect(await latest.value == ["latest"])
        #expect(!started)
    }

    @Test
    func givenActiveRequest_whenCallerCancels_thenDiscardsResponse() async {
        let sut = TunnelLogRequest()
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
        #expect(await caller.value == [])
        #expect(await sut.fetch { ["next"] } == ["next"])
    }

    @Test
    func givenCancelledCaller_whenFetching_thenDoesNotStartRequest() async {
        let sut = TunnelLogRequest()
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await sut.fetch {
                Issue.record("Cancelled caller started a log request")
                return ["unexpected"]
            }
        }
        #expect(await task.value == [])
    }
}
