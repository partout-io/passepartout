// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import CommonLibrary
@testable import CommonLibraryCore
import Partout
import Testing

extension IAPManagerTests {
    @Test
    func givenPendingReceipt_whenDisabledAndReenabled_thenDiscardsCancelledResult() async throws {
        let reader = SuspendedReceiptReader()
        let sut = IAPManager(receiptReader: reader)
        let first = Task { await sut.reloadReceipt() }
        try await reader.started[0].fulfillment(timeout: CommonLibraryTests.timeout)
        #expect(sut.isLoadingReceipt)

        sut.isEnabled = false
        #expect(!sut.isLoadingReceipt)
        await sut.reloadReceipt()

        sut.isEnabled = true
        let second = Task { await sut.reloadReceipt() }
        try await reader.started[1].fulfillment(timeout: CommonLibraryTests.timeout)
        #expect(sut.isLoadingReceipt)

        reader.finish(0, build: 100)
        await first.value
        #expect(sut.originalPurchase == nil)
        #expect(sut.isLoadingReceipt)

        reader.finish(1, build: 200)
        await second.value
        #expect(sut.originalPurchase?.buildNumber == 200)
        #expect(!sut.isLoadingReceipt)
    }
}

@BusinessActor
private final class SuspendedReceiptReader: UserInAppReceiptReader {
    let started = [Expectation(), Expectation()]
    private var continuations: [CheckedContinuation<ABI.StoreReceipt?, Never>] = []

    func receipt(at userLevel: ABI.AppUserLevel) async -> ABI.StoreReceipt? {
        let index = continuations.count
        return await withCheckedContinuation { continuation in
            continuations.append(continuation)
            Task { await started[index].fulfill() }
        }
    }

    func addPurchase(with identifier: String) {}

    func finish(_ index: Int, build: Int) {
        continuations[index].resume(returning: ABI.StoreReceipt(
            originalPurchase: ABI.OriginalPurchase(buildNumber: build),
            purchaseReceipts: []
        ))
    }
}
