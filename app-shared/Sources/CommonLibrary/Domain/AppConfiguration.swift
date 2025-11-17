// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension ABI {
    public enum AppTarget {
        case app
        case tunnel
    }

    public enum BundleKey: String, CaseIterable, Decodable {
        case appStoreId
        case cloudKitId
        case userLevel
        case groupId
        case iapBundlePrefix
        case keychainGroupId
        case loginItemId
        case tunnelId

        static let requiredAppKeys = Set(allCases)
            .subtracting([.userLevel])
        static let requiredTunnelKeys: Set<Self> = [
            .groupId,
            .keychainGroupId,
            .tunnelId
        ]
    }

    public struct AppConfiguration: Decodable, Sendable {
        public let constants: ABI.Constants

        public let displayName: String
        public let versionNumber: String
        public let buildNumber: Int
        public let versionString: String
        private let bundleValues: JSON

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
            bundleValues = [:]

            let dummyURL = URL(fileURLWithPath: "")
            urlForAppLog = dummyURL
            urlForTunnelLog = dummyURL
            urlForReview = dummyURL
        }

        public init(
            _ bundle: BundleConfiguration,
            constants: Constants,
            target: AppTarget,
            distributionTarget: DistributionTarget
        ) {
            self.constants = constants
            displayName = bundle.displayName
            versionNumber = bundle.versionNumber
            buildNumber = bundle.buildNumber
            versionString = bundle.versionString

            let bundleMap = BundleKey.allCases.reduce(into: [:]) {
                switch $1 {
                case .appStoreId, .cloudKitId, .groupId,
                        .iapBundlePrefix, .keychainGroupId,
                        .loginItemId, .tunnelId:
                    $0[$1] = bundle.string(for: $1)
                case .userLevel:
                    if let userLevel = bundle.integerIfPresent(for: $1) {
                        $0[$1] = userLevel
                    }
                }
            }
            do {
                bundleValues = try JSON(bundleMap)

                // All required, except .userLevel is optional
                let requiredKeys: Set<BundleKey>
                switch target {
                case .app:
                    requiredKeys = BundleKey.requiredAppKeys
                case .tunnel:
                    requiredKeys = BundleKey.requiredTunnelKeys
                }

                // Ensure all required keys are present
                let foundKeys = bundleValues.objectValue.map { Set($0.keys) } ?? []
                guard foundKeys.isSuperset(of: Set(requiredKeys.map(\.rawValue))) else {
                    throw PartoutError(.decoding)
                }
            } catch {
                fatalError("Unable to fetch required bundle values: \(error)")
            }

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
                if distributionTarget.supportsAppGroups {
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

        public func bundleString(for key: ABI.BundleKey) -> String {
            guard let value = bundleValues[key.rawValue]?.stringValue else {
                fatalError("Missing bundle value in JSON for: \(key.rawValue)")
            }
            return value
        }

        public func bundleIntegerIfPresent(for key: ABI.BundleKey) -> Int? {
            bundleValues[key.rawValue]?.doubleValue.map { Int($0) }
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

    func integerIfPresent(for key: ABI.BundleKey) -> Int? {
        value(forKey: key.rawValue)
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
