// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppAccessibility
@_exported import AppLibrary
import CommonLibrary
import TipKit

public final class AppLibraryMain: AppLibraryConfiguring {
    public init() {
    }

    public func configure(with context: AppContext) {
        assertMissingImplementations(with: context.registry)

        if #available(iOS 17, macOS 14, *) {

            // for debugging
//            Tips.showAllTipsForTesting()
            if AppCommandLine.contains(.uiTesting) {
                Tips.hideAllTipsForTesting()
            }

            try? Tips.configure([
                .displayFrequency(.immediate)
            ])
        }
    }
}

private extension AppLibraryMain {
    func assertMissingImplementations(with registry: Registry) {
        ModuleType.allCases.forEach { moduleType in
            let builder = moduleType.newModule(with: registry)

            // ModuleViewProviding
            guard builder is any ModuleViewProviding else {
                fatalError("\(moduleType): is not ModuleViewProviding")
            }
        }
    }
}
