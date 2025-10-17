// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonUtils

extension Dependencies {
    nonisolated var customUserLevel: AppUserLevel? {
        guard let userLevelInteger = BundleConfiguration.mainIntegerIfPresent(for: .userLevel),
              let userLevel = AppUserLevel(rawValue: userLevelInteger) else {
            return nil
        }
        return userLevel
    }

    func appProductHelper() -> any AppProductHelper {
        StoreKitHelper(
            products: AppProduct.all,
            inAppIdentifier: {
                let prefix = BundleConfiguration.mainString(for: .iapBundlePrefix)
                return "\(prefix).\($0.rawValue)"
            }
        )
    }

    nonisolated func betaChecker() -> BetaChecker {
        TestFlightChecker()
    }

    nonisolated func productsAtBuild() -> BuildProducts<AppProduct> {
        { purchase in
#if os(iOS)
            if purchase.isBefore(.freemium) {
                return [.Essentials.iOS]
            } else if purchase.isBefore(.v2) {
                return [.Features.networkSettings]
            }
            return []
#elseif os(macOS)
            if purchase.isBefore(.v2) {
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
