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

    public var supportsIAP: Bool {
        self == .appStore
    }

    // Differs from !supportsIAP because:
    //
    // - .appStore supports paid features and IAP
    // - .enterprise supports paid features but not IAP
    // - .developerID supports neither
    public var supportsPaidFeatures: Bool {
        self != .developerID
    }
}
