// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonProviders
import Partout

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

#if canImport(CommonLibraryWeb)
    public static let webUploaderPath: String = {
        guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
            fatalError("Unable to find web_uploader.html in Resources")
        }
        return path
    }()
#endif
}

extension API {
    public static var shared: [APIMapper] {
#if DEBUG
        API.bundled
#else
        API.remoteThenBundled
#endif
    }

    public static let bundled: [APIMapper] = [
        Self.bundledV7
    ]

    private static let remoteThenBundled: [APIMapper] = [
        Self.remoteV7,
        Self.bundledV7
    ]
}

private extension API {
    static let version = 7

    // use local JS (baseURL = local)
    // fetch remote JSON (URL in scripts)
    static let bundledV7: APIMapper = {
        guard let bundledURL = API.url(forVersion: version) else {
            fatalError("Unable to find bundled API")
        }
        return DefaultAPIMapper(.global, baseURL: bundledURL, timeout: Resources.constants.api.timeoutInterval)
    }()

    // fetch remote JS (baseURL = remote)
    // fetch remote JSON (URL in scripts)
    static let remoteV7: APIMapper = {
        let remoteURL = Resources.constants.websites.api.appendingPathComponent("v\(version)")
        return DefaultAPIMapper(.global, baseURL: remoteURL, timeout: Resources.constants.api.timeoutInterval)
    }()
}
