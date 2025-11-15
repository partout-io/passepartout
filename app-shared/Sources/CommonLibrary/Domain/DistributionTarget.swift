// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ABI {
    public enum DistributionTarget: String, Sendable {
        case appStore

        case developerID

        // TODO: #13, behave like .complete when this is implemented
        case enterprise
    }
}

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

    // differs from !supportsIAP because:
    //
    // - .appStore supports paid features and IAP
    // - .enterprise supports paid features but not IAP
    // - .developerID supports neither
    public var supportsPaidFeatures: Bool {
        self != .developerID
    }

    public var usesExperimentalPOSIXResolver: Bool {
        self == .developerID
    }
}
