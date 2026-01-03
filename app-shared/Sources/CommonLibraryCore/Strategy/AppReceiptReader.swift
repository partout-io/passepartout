// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

public protocol AppReceiptReader: Sendable {
    func receipt(at userLevel: ABI.AppUserLevel) async -> InAppReceipt?

    func addPurchase(with identifier: String) async
}
