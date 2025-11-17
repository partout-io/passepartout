// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonResources
import Partout

extension Dependencies {
    @MainActor
    func appProductHelper() -> any AppProductHelper {
        StoreKitHelper(
            products: ABI.AppProduct.all,
            inAppIdentifier: {
                let prefix = appConfiguration.bundleString(for: .iapBundlePrefix)
                return "\(prefix).\($0.rawValue)"
            }
        )
    }

    func betaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    func productsAtBuild() -> BuildProducts<ABI.AppProduct> {
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

    func iapLogger() -> LoggerProtocol {
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
