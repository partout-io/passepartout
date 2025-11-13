// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import CommonProviders
import Partout

extension Constants {
    public static let shared = Bundle.module.unsafeDecode(Constants.self, filename: "Constants")
}

#if canImport(CommonLibraryWeb)
import CommonLibraryWeb

extension NIOWebReceiver {
    public static func webUploaderPath() throws -> String {
        guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
            throw AppError.notFound
        }
        return path
    }
}

#endif

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
        return DefaultAPIMapper(.global, baseURL: bundledURL, timeout: Constants.shared.api.timeoutInterval)
    }()

    // fetch remote JS (baseURL = remote)
    // fetch remote JSON (URL in scripts)
    static let remoteV7: APIMapper = {
        let remoteURL = Constants.shared.websites.api.appendingPathComponent("v\(version)")
        return DefaultAPIMapper(.global, baseURL: remoteURL, timeout: Constants.shared.api.timeoutInterval)
    }()
}
