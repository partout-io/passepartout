// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)
import AppKit
#endif
import Foundation
#if !os(macOS)
import UIKit
#endif

public struct SystemInformation {
    public let osString: String

    public let deviceString: String?

    public init() {
#if os(macOS)
        let os = ProcessInfo().operatingSystemVersion
        let osName = "macOS"
        let osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        deviceString = nil
#else
        let device: UIDevice = .current
        let osName = device.systemName
        let osVersion = device.systemVersion
        deviceString = device.model
#endif
        osString = "\(osName) \(osVersion)"
    }
}
