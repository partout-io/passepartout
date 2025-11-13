// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

public enum Resources {
    public static let constants = Bundle.module.unsafeDecode(Constants.self, filename: "Constants")

    public static let credits = Bundle.module.unsafeDecode(Credits.self, filename: "Credits")

    public static let issueTemplate: String = {
        do {
            guard let templateURL = Bundle.module.url(forResource: "Issue", withExtension: "txt") else {
                fatalError("Unable to find Issue.txt in Resources")
            }
            return try String(contentsOf: templateURL)
        } catch {
            fatalError("Unable to parse Issue.txt: \(error)")
        }
    }()

#if os(tvOS)
    public static let webUploaderPath: String = {
        guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
            fatalError("Unable to find web_uploader.html in Resources")
        }
        return path
    }()
#endif
}
