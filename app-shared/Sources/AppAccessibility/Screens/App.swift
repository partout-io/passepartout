// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension AccessibilityInfo {
    public enum App {
        public enum ProfileMenu {
            public static let edit = AccessibilityInfo("app.profileMenu.edit", .menuItem)

            public static let connectTo = AccessibilityInfo("app.profileMenu.connectTo", .menuItem)
        }

        public enum ProfileList {
            public static let profile = AccessibilityInfo("app.profileList.profile", .button)
        }

        public static let profilesHeader = AccessibilityInfo("app.profilesHeader", .text)

        public static let profileToggle = AccessibilityInfo("app.profileToggle", .toggle)

        public static let profileEdit = AccessibilityInfo("app.profileEdit", .button)
    }
}
