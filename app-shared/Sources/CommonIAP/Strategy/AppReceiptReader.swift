// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonUtils
import Foundation

public protocol AppReceiptReader {
    func receipt(at userLevel: AppUserLevel) async -> InAppReceipt?

    func addPurchase(with identifier: String) async
}
