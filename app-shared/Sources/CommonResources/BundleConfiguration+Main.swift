// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

// WARNING: beware of Resources.constants dependency

extension BundleConfiguration {
    public enum BundleKey: String {
        case appStoreId

        case cloudKitId

        case userLevel

        case groupId

        case iapBundlePrefix

        case keychainGroupId

        case loginItemId

        case tunnelId
    }

    public static var mainDisplayName: String {
        if isPreview {
            return "preview-display-name"
        }
        return main.displayName
    }

    public static var mainVersionNumber: String {
        if isPreview {
            return "preview-1.2.3"
        }
        return main.versionNumber
    }

    public static var mainBuildNumber: Int {
        if isPreview {
            return 12345
        }
        return main.buildNumber
    }

    public static var mainVersionString: String {
        if isPreview {
            return "preview-1.2.3-1234"
        }
        return main.versionString
    }

    public static func mainString(for key: BundleKey) -> String {
        if isPreview {
            return "preview-key(\(key.rawValue))"
        }
        guard let value: String = main.value(forKey: key.rawValue) else {
            fatalError("Missing main bundle key: \(key.rawValue)")
        }
        return value
    }

    public static func mainIntegerIfPresent(for key: BundleKey) -> Int? {
        if isPreview {
            return nil
        }
        return main.value(forKey: key.rawValue)
    }

    public static var urlForReview: URL {
        let appStoreId = mainString(for: .appStoreId)
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else {
            fatalError("Unable to build urlForReview")
        }
        return url
    }
}

private extension BundleConfiguration {

    // WARNING: fails from package itself, e.g. in previews
    static var main: BundleConfiguration {
        guard let bundle = BundleConfiguration(.main, key: Resources.constants.bundleKey) else {
            fatalError("Missing main bundle")
        }
        return bundle
    }

    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
