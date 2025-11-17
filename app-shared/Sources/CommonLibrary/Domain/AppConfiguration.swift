// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    fileprivate enum BundleKey: String, Decodable {
        case appStoreId
        case cloudKitId
        case userLevel
        case groupId
        case iapBundlePrefix
        case keychainGroupId
        case loginItemId
        case tunnelId
    }

    public struct AppConfiguration: Decodable, Sendable {
        public let constants: ABI.Constants

        public let displayName: String
        public let versionNumber: String
        public let buildNumber: Int
        public let versionString: String

        public let urlForAppLog: URL
        public let urlForTunnelLog: URL
        public let urlForReview: URL

        // For previews
        public init(constants: Constants) {
            self.constants = constants
            displayName = "preview-display-name"
            versionNumber = "preview-1.2.3"
            buildNumber = 12345
            versionString = "preview-1.2.3-1234"

            let dummyURL = URL(fileURLWithPath: "")
            urlForAppLog = dummyURL
            urlForTunnelLog = dummyURL
            urlForReview = dummyURL
        }

        public init(_ bundle: BundleConfiguration, constants: Constants, target: DistributionTarget) {
            self.constants = constants
            displayName = bundle.displayName
            versionNumber = bundle.versionNumber
            buildNumber = bundle.buildNumber
            versionString = bundle.versionString

            let appGroupURL = {
                let groupId = bundle.string(for: .groupId)
                guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
                    pp_log_g(.App.core, .error, "Unable to access App Group container")
                    return FileManager.default.temporaryDirectory
                }
                return url
            }()

            urlForAppLog = appGroupURL.forCaches.appending(path: constants.log.appPath)
            urlForTunnelLog = {
                let baseURL: URL
                if target.supportsAppGroups {
                    baseURL = appGroupURL.forCaches
                } else {
                    let fm: FileManager = .default
                    baseURL = fm.temporaryDirectory
                    do {
                        try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
                    } catch {
                        pp_log_g(.App.core, .error, "Unable to create temporary directory \(baseURL): \(error)")
                    }
                }
                return baseURL.appending(path: constants.log.tunnelPath)
            }()
            urlForReview = {
                let appStoreId = bundle.string(for: .appStoreId)
                guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else {
                    fatalError("Unable to build urlForReview")
                }
                return url
            }()
        }
    }
}

private extension BundleConfiguration {
    func string(for key: ABI.BundleKey) -> String {
        guard let value: String = value(forKey: key.rawValue) else {
            fatalError("Missing main bundle key: \(key.rawValue)")
        }
        return value
    }
}

// App Group container is not available on tvOS (#1007)

#if !os(tvOS)

private extension URL {
    var forCaches: URL {
        let url = appending(components: "Library", "Caches")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create group caches directory: \(error)")
        }
        return url
    }

    var forDocuments: URL {
        let url = appending(components: "Library", "Documents")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create group documents directory: \(error)")
        }
        return url
    }
}

#else

private extension URL {
    var forCaches: URL {
        do {
            return try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    var forDocuments: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

#endif
