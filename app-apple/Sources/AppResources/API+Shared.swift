// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

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
        let remoteURL = Resources.constants.websites.api.miniAppending(path: "v\(version)")
        return DefaultAPIMapper(.global, baseURL: remoteURL, timeout: Resources.constants.api.timeoutInterval)
    }()
}
