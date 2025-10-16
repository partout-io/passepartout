// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils

public actor SharedReceiptReader: AppReceiptReader {
    private let reader: InAppReceiptReader

    private var pendingTask: Task<InAppReceipt?, Never>?

    public init(reader: InAppReceiptReader & Sendable) {
        self.reader = reader
    }

    public func receipt(at userLevel: AppUserLevel) async -> InAppReceipt? {
        if let pendingTask {
            _ = await pendingTask.value
        }
        pendingTask = Task {
            await asyncReceipt(at: userLevel)
        }
        let receipt = await pendingTask?.value
        pendingTask = nil
        return receipt
    }

    public func addPurchase(with identifier: String) async {
        //
    }
}

private extension SharedReceiptReader {
    func asyncReceipt(at userLevel: AppUserLevel) async -> InAppReceipt? {
        pp_log_g(.App.iap, .info, "\tParse receipt for user level \(userLevel)")
        pp_log_g(.App.iap, .info, "\tRead receipt")
        return await reader.receipt()
    }
}
