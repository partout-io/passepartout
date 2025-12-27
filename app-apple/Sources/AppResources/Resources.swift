// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary

public enum Resources {
    public static func newAppConfiguration(
        distributionTarget: ABI.DistributionTarget,
        buildTarget: ABI.BuildTarget
    ) -> ABI.AppConfiguration {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isPreview {
            return ABI.AppConfiguration(constants: constants, distributionTarget: .appStore)
        }
        // WARNING: This fails from package itself, e.g. in previews
        guard let bundle = BundleConfiguration(.main, key: "AppConfig") else {
            fatalError("Missing main bundle")
        }
        return ABI.AppConfiguration(
            constants: constants,
            distributionTarget: distributionTarget,
            buildTarget: buildTarget,
            bundle: bundle
        )
    }

    // Do not expose this to views, use AppConfiguration.constants from environment
    static let constants = Bundle.module.unsafeDecode(ABI.Constants.self, filename: "Constants")

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

#if os(tvOS)
    public static let webUploaderPath: String = {
        guard let path = Bundle.module.path(forResource: "web_uploader", ofType: "html") else {
            fatalError("Unable to find web_uploader.html in Resources")
        }
        return path
    }()
#endif
}
