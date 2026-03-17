// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Partout

public enum Resources {
    public static func newAppConfiguration(
        distributionTarget: ABI.DistributionTarget,
        buildTarget: ABI.AppBundle.BuildTarget
    ) -> ABI.AppConfiguration {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            let bundle = ABI.AppBundle(distributionTarget: .appStore)
            return ABI.AppConfiguration(bundle: bundle, constants: constants)
        }
        // WARNING: This fails from package itself, e.g. in previews
        guard let bundleConfiguration = BundleConfiguration(.main, key: "AppConfig") else {
            fatalError("Missing main bundle")
        }
        let bundle = ABI.AppBundle(
            distributionTarget: distributionTarget,
            buildTarget: buildTarget,
            bundle: bundleConfiguration,
            logTag: "BlockbitVPN",
            appLogPath: "app.log",
            tunnelLogPath: "tunnel.log"
        )
        return ABI.AppConfiguration(bundle: bundle, constants: constants)
    }

    // Do not expose this to views, use AppConfiguration.constants from environment
    static let constants = Bundle.module.unsafeDecode(ABI.AppConstants.self, filename: "Constants")

    nonisolated(unsafe)
    public static let credits = Bundle.module.unsafeDecode(ABI.Credits.self, filename: "Credits")

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

    public static let webUploaderPath: String? = {
#if os(tvOS)
        guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
            fatalError("Unable to find web_uploader.html in Resources")
        }
        return path
#else
        nil
#endif
    }()
}
