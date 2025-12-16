// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if !PSP_MONOLITH
import CommonLibraryCore
#endif
import Partout

extension ABI.AppConfiguration {
    public enum BundleKey: String, CaseIterable, Decodable, Sendable {
        // These cases are all strings
        case appStoreId
        case cloudKitId
        case groupId
        case iapBundlePrefix
        case keychainGroupId
        case loginItemId
        case tunnelId

        // This is an integer number
        case userLevel

        static func requiredKeys(for target: ABI.BuildTarget) -> Set<Self> {
            switch target {
            case .app: Set(allCases).subtracting([.userLevel])
            case .tunnel: [.groupId, .keychainGroupId, .tunnelId]
            }
        }
    }

    public init(
        constants: ABI.Constants,
        distributionTarget: ABI.DistributionTarget,
        buildTarget: ABI.BuildTarget,
        bundle: BundleConfiguration
    ) {
        let displayName = bundle.displayName
        let versionNumber = bundle.versionNumber
        let buildNumber = bundle.buildNumber
        let versionString = bundle.versionString

        // Ensure that all required keys are present (will crash on first missing)
        let requiredBundleKeys = BundleKey.requiredKeys(for: buildTarget)
        let bundleStrings = requiredBundleKeys.reduce(into: [:]) {
            $0[$1.rawValue] = bundle.string(for: $1)
        }

        // Fetch user level manually
        let customUserLevel = bundle.integerIfPresent(for: .userLevel).map {
            ABI.AppUserLevel(rawValue: $0)
        } ?? nil

        let appGroupURL = {
            let groupId = bundle.string(for: .groupId)
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
                pp_log_g(.App.core, .error, "Unable to access App Group container")
                return FileManager.default.temporaryDirectory
            }
            return url
        }()

        let urlForAppLog = appGroupURL.forCaches.appending(path: constants.log.appPath)
        let urlForTunnelLog = {
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

        let urlForReview: URL?
        if requiredBundleKeys.contains(.appStoreId) {
            urlForReview = {
                let appStoreId = bundle.string(for: .appStoreId)
                guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else {
                    fatalError("Unable to build urlForReview")
                }
                return url
            }()
        } else {
            urlForReview = nil
        }

        self.init(
            constants: constants,
            distributionTarget: distributionTarget,
            displayName: displayName,
            versionNumber: versionNumber,
            buildNumber: buildNumber,
            versionString: versionString,
            customUserLevel: customUserLevel,
            bundleStrings: bundleStrings,
            urlForAppLog: urlForAppLog,
            urlForTunnelLog: urlForTunnelLog,
            urlForReview: urlForReview
        )
    }

    public func bundleString(for key: ABI.AppConfiguration.BundleKey) -> String {
        guard let value = bundleStrings[key.rawValue] else {
            fatalError("Missing bundle value in JSON for: \(key.rawValue)")
        }
        return value
    }
}

private extension BundleConfiguration {
    func string(for key: ABI.AppConfiguration.BundleKey) -> String {
        guard let value: String = value(forKey: key.rawValue) else {
            fatalError("Missing main bundle key: \(key.rawValue)")
        }
        return value
    }

    func integerIfPresent(for key: ABI.AppConfiguration.BundleKey) -> Int? {
        value(forKey: key.rawValue)
    }
}

// App Group container is not available on tvOS (#1007)

#if !os(tvOS)

private extension URL {
    var forCaches: Self {
        let url = appending(components: "Library", "Caches")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            pp_log_g(.App.core, .fault, "Unable to create group caches directory: \(error)")
        }
        return url
    }

    var forDocuments: Self {
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
