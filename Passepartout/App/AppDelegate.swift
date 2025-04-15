//
//  AppDelegate.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/18/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
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

import CommonLibrary
import SwiftUI
import UIAccessibility
import UILibrary

@MainActor
final class AppDelegate: NSObject {
    let context: AppContext = {
        if AppCommandLine.contains(.uiTesting) {
            let dependencies: Dependencies = .shared
            pp_log(.app, .info, "UI tests: mock AppContext")
            return .forUITesting(withRegistry: dependencies.registry)
        }
        return .shared
    }()

#if os(macOS)
    let settings = MacSettingsModel(
        defaults: .standard,
        loginItemId: BundleConfiguration.mainString(for: .loginItemId)
    )
#endif

    func configure(with uiConfiguring: UILibraryConfiguring) {
        UILibrary(uiConfiguring)
            .configure(with: context)
    }
}
