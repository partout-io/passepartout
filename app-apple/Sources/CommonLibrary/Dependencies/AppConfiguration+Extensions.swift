// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

// MARK: AppBundle

extension ABI.AppBundle {
    public enum BuildTarget: Sendable {
        case app
        case tunnel
    }

    public enum BundleKey: String, CaseIterable, Decodable, Sendable {
        // These cases are all strings
        case appStoreId
        case cloudKitId
        case groupId
        case iapBundlePrefix
        case keychainGroupId
        case loginItemId
        case tunnelId
        case userLevel

        static func requiredKeys(for target: BuildTarget) -> Set<Self> {
            switch target {
            case .app: Set(allCases).subtracting([.userLevel])
            case .tunnel: [.groupId, .keychainGroupId, .tunnelId]
            }
        }
    }

    public init(
        distributionTarget: ABI.DistributionTarget,
        buildTarget: BuildTarget,
        bundle: BundleConfiguration
    ) {
        let displayName = bundle.displayName
        let versionNumber = bundle.versionNumber
        let buildNumber = bundle.buildNumber

        // Ensure that all required keys are present (will crash on first missing)
        let requiredBundleKeys = BundleKey.requiredKeys(for: buildTarget)
        let bundleStrings = requiredBundleKeys.reduce(into: [:]) {
            $0[$1.rawValue] = bundle.string(for: $1)
        }

        // Fetch user level manually
        let customUserLevel = bundle.stringIfPresent(for: .userLevel).map {
            ABI.AppUserLevel(rawValue: $0)
        } ?? nil

        self.init(
            distributionTarget: distributionTarget,
            displayName: displayName,
            versionNumber: versionNumber,
            buildNumber: buildNumber,
            customUserLevel: customUserLevel,
            bundleStrings: bundleStrings
        )
    }

    public func bundleString(for key: ABI.AppBundle.BundleKey) -> String {
        guard let value = bundleStrings?[key.rawValue] else {
            fatalError("Missing bundle value in JSON for: \(key.rawValue)")
        }
        return value
    }
}

private extension ABI.AppBundle {
    static let log = SimpleLogDestination()

    var appGroupURL: URL {
        let groupId = bundleString(for: .groupId)
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) else {
            Self.log.append(.error, "Unable to access App Group container")
            return FileManager.default.temporaryDirectory
        }
        return url
    }

    var appLogsURL: URL {
        appGroupURL.forCaches
    }

    var tunnelLogsURL: URL {
        let baseURL: URL
        if distributionTarget.supportsAppGroups {
            baseURL = appGroupURL.forCaches
        } else {
            let fm: FileManager = .default
            baseURL = fm.temporaryDirectory
            do {
                try fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
            } catch {
                Self.log.append(.error, "Unable to create temporary directory \(baseURL): \(error)")
            }
        }
        return baseURL
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
            SimpleLogDestination().append(.fault, "Unable to create group caches directory: \(error)")
        }
        return url
    }

    var forDocuments: Self {
        let url = appending(components: "Library", "Documents")
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create group documents directory: \(error)")
        }
        return url
    }
}

#else

// XXX: This is weird, behavior is static but signatures are non-static
private extension URL {
    var forCaches: URL {
        do {
            return try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create user caches directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    var forDocuments: URL {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            SimpleLogDestination().append(.fault, "Unable to create user documents directory: \(error)")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

#endif

private extension BundleConfiguration {
    func string(for key: ABI.AppBundle.BundleKey) -> String {
        guard let value: String = value(forKey: key.rawValue) else {
            fatalError("Missing main bundle key: \(key.rawValue)")
        }
        return value
    }

    func stringIfPresent(for key: ABI.AppBundle.BundleKey) -> String? {
        value(forKey: key.rawValue)
    }

    func integerIfPresent(for key: ABI.AppBundle.BundleKey) -> Int? {
        value(forKey: key.rawValue)
    }
}

// MARK: - AppConfiguration

extension ABI.AppConfiguration {
    public var appLogPath: String {
        constants.log.filenames.app
    }

    public var tunnelLogPath: String {
        constants.log.filenames.tunnel
    }

    public var urlForAppLog: URL {
        bundle.appLogsURL.appending(path: appLogPath)
    }

    public var urlForTunnelLog: URL {
        bundle.tunnelLogsURL.appending(path: tunnelLogPath)
    }

    public var urlForReview: URL? {
        let requiredKeys = ABI.AppBundle.BundleKey.requiredKeys(for: .app)
        guard requiredKeys.contains(.appStoreId) else {
            return nil
        }
        let appStoreId = bundle.bundleString(for: .appStoreId)
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else {
            fatalError("Unable to build urlForReview")
        }
        return url
    }
}
