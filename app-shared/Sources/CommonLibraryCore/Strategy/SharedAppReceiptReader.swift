// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public actor SharedReceiptReader: UserInAppReceiptReader {
    private let reader: InAppReceiptReader

    private var pendingTask: Task<ABI.StoreReceipt?, Never>?

    public init(reader: InAppReceiptReader) {
        self.reader = reader
    }

    public func receipt(at userLevel: ABI.AppUserLevel) async -> ABI.StoreReceipt? {
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
    func asyncReceipt(at userLevel: ABI.AppUserLevel) async -> ABI.StoreReceipt? {
        pp_log_g(.App.iap, .info, "\tParse receipt for user level \(userLevel)")
        pp_log_g(.App.iap, .info, "\tRead receipt")
        return await reader.receipt()
    }
}
