//
//  Issue.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/18/24.
//  Copyright (c) 2024 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

#if os(iOS)
import CommonLibrary
import Foundation
import UIKit
#else
import AppKit
import CommonLibrary
import Foundation
#endif

struct Issue: Identifiable {
    let id: UUID

    let appLine: String?

    let purchasedProducts: Set<AppProduct>

    let appLog: Data?

    let tunnelLog: Data?

    let osLine: String

    let deviceLine: String?

    init(appLine: String?, purchasedProducts: Set<AppProduct>, appLog: Data? = nil, tunnelLog: Data? = nil) {
        id = UUID()
        self.appLine = appLine
        self.purchasedProducts = purchasedProducts
        self.appLog = appLog
        self.tunnelLog = tunnelLog

        let osName: String
        let osVersion: String
        let deviceType: String?
        // providerName / providerLastUpdate

#if os(iOS)
        let device: UIDevice = .current
        osName = device.systemName
        osVersion = device.systemVersion
        deviceType = device.model
#else
        let os = ProcessInfo().operatingSystemVersion
        osName = "macOS"
        osVersion = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        deviceType = nil
#endif

        osLine = "\(osName) \(osVersion)"
        deviceLine = deviceType
    }

    var body: String {
        template
            .replacingOccurrences(of: "$appLine", with: appLine ?? "unknown")
            .replacingOccurrences(of: "$osLine", with: osLine)
            .replacingOccurrences(of: "$deviceLine", with: deviceLine ?? "unknown")
        // TODO: replace with provider later
            .replacingOccurrences(of: "$providerName", with: "none")
            .replacingOccurrences(of: "$providerLastUpdate", with: "unknown")
            .replacingOccurrences(of: "$purchasedProducts", with: purchasedProducts.map(\.rawValue).description)
    }
}

private extension Issue {
    var template: String {
        do {
            guard let templateURL = Bundle.module.url(forResource: "Issue", withExtension: "txt") else {
                fatalError("Unable to find Issue.txt in Resources")
            }
            return try String(contentsOf: templateURL)
        } catch {
            fatalError("Unable to parse Issue.txt: \(error)")
        }
    }
}
