// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

extension Issue {
    public var template: String {
        do {
            guard let templateURL = Bundle.module.url(forResource: "Issue", withExtension: "txt") else {
                fatalError("Unable to find Issue.txt in Resources")
            }
            return try String(contentsOf: templateURL)
        } catch {
            fatalError("Unable to parse Issue.txt: \(error)")
        }
    }
}
