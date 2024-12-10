//
//  App.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/27/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

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

        public static let installedProfile = AccessibilityInfo("app.installedProfile", .text)

        public static let profileToggle = AccessibilityInfo("app.profileToggle", .button)

        public static let profileMenu = AccessibilityInfo("app.profileMenu", .menu)
    }
}
