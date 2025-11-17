// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Partout

extension Dependencies {
    func appProductHelper(cfg: ABI.AppConfiguration) -> any AppProductHelper {
        StoreKitHelper(
            products: ABI.AppProduct.all,
            inAppIdentifier: {
                let prefix = cfg.bundleString(for: .iapBundlePrefix)
                return "\(prefix).\($0.rawValue)"
            }
        )
    }

    nonisolated func betaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    nonisolated func productsAtBuild() -> BuildProducts<ABI.AppProduct> {
        { purchase in
#if os(iOS)
            if purchase.isUntil(.freemium) {
                return [.Essentials.iOS]
            } else if purchase.isUntil(.v2) {
                return [.Features.networkSettings]
            }
            return []
#elseif os(macOS)
            if purchase.isUntil(.v2) {
                return [.Features.networkSettings]
            }
            return []
#else
            return []
#endif
        }
    }

    nonisolated func iapLogger() -> LoggerProtocol {
        IAPLogger()
    }
}

private struct IAPLogger: LoggerProtocol {
    func debug(_ msg: String) {
        pp_log_g(.App.iap, .info, msg)
    }

    func warning(_ msg: String) {
        pp_log_g(.App.iap, .error, msg)
    }
}
