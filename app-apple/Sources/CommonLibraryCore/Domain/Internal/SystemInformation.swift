// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

#if os(macOS)
import AppKit
#elseif os(iOS) || os(tvOS)
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
#elseif os(iOS) || os(tvOS)
        let deviceInfo = if Thread.isMainThread {
            MainActor.assumeIsolated { Self.deviceInformation() }
        } else {
            DispatchQueue.main.sync { Self.deviceInformation() }
        }
        let osName = deviceInfo.systemName
        let osVersion = deviceInfo.systemVersion
        deviceString = deviceInfo.model
#else
        let osName = "Unknown"
        let osVersion = "0.0.0"
        deviceString = nil
#endif
        osString = "\(osName) \(osVersion)"
    }
}

#if os(iOS) || os(tvOS)
private extension SystemInformation {
    struct DeviceInformation {
        let systemName: String
        let systemVersion: String
        let model: String
    }

    @MainActor
    static func deviceInformation() -> DeviceInformation {
        let device = UIDevice.current
        return DeviceInformation(
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            model: device.model
        )
    }
}
#endif
