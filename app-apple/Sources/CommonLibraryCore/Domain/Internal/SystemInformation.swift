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
        osString = "macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        deviceString = nil
#elseif os(iOS) || os(tvOS)
        let deviceInfo = if Thread.isMainThread {
            MainActor.assumeIsolated { Self.deviceInformation() }
        } else {
            DispatchQueue.main.sync { Self.deviceInformation() }
        }
        osString = deviceInfo.osString
        deviceString = deviceInfo.model
#else
        osString = "Unknown 0.0.0"
        deviceString = nil
#endif
    }
}

#if os(iOS) || os(tvOS)
private extension SystemInformation {
    @MainActor
    static func deviceInformation() -> (osString: String, model: String) {
        let device = UIDevice.current
        return ("\(device.systemName) \(device.systemVersion)", device.model)
    }
}
#endif
