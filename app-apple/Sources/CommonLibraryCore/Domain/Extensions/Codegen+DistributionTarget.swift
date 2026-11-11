// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI.DistributionTarget {
    public var canAlwaysReportIssue: Bool {
        self == .enterprise
    }

    public var supportsAppGroups: Bool {
        self != .developerID
    }

    public var supportsCloudKit: Bool {
        self != .developerID
    }

    public var usesInAppPurchases: Bool {
        self == .appStore
    }

    // Feature availability is independent of purchasing:
    //
    // - .appStore supports all features and uses in-app purchases
    // - .enterprise supports all features without in-app purchases
    // - .developerID supports a limited feature set without in-app purchases
    public var supportsAllFeatures: Bool {
        self != .developerID
    }
}
