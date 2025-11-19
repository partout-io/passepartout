// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension AccessibilityInfo {
    public enum Profile {
        public static let name = AccessibilityInfo("profile.name", .text)

        public static let moduleLink = AccessibilityInfo("profile.moduleLink", .link)

        public static let providerServerLink = AccessibilityInfo("profile.providerServerLink", .link)

        public static let cancel = AccessibilityInfo("profile.cancel", .button)
    }
}
