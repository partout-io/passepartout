// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

extension ABI {
    public struct SystemInformation {
        public let osString: String

        public let deviceString: String?

        public init() {
#if os(macOS)
            let os = ProcessInfo().operatingSystemVersion
            let osName = "macOS"
            let osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
            deviceString = nil
#elseif os(iOS) || os(tvOS)
            let device: UIDevice = .current
            let osName = device.systemName
            let osVersion = device.systemVersion
            deviceString = device.model
#else
            // TODO: ###, Non-Apple OS information
            let osName = "Unknown"
            let osVersion = "0.0.0"
            deviceString = nil
#endif
            osString = "\(osName) \(osVersion)"
        }
    }
}
