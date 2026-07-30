// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol InAppReceiptReader: Sendable {
    func receipt() async -> ABI.StoreReceipt?
}

public protocol UserInAppReceiptReader: Sendable {
    func receipt(at userLevel: ABI.AppUserLevel) async -> ABI.StoreReceipt?

    func addPurchase(with identifier: String) async
}
