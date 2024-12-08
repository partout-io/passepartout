//
//  AppContext+Testing.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/28/24.
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

import CommonLibrary
import CommonUtils
import Foundation
import PassepartoutKit
import UILibrary

extension AppContext {
    static func forUITesting(withRegistry registry: Registry) -> AppContext {
        let dependencies: Dependencies = .shared
        let iapManager = IAPManager(
            customUserLevel: .subscriber,
            inAppHelper: dependencies.appProductHelper(),
            receiptReader: FakeAppReceiptReader(),
            betaChecker: TestFlightChecker(),
            productsAtBuild: { _ in
                []
            }
        )
        let processor = dependencies.appProcessor(with: iapManager)
        let profileManager: ProfileManager = .forUITesting(
            withRegistry: dependencies.registry,
            processor: processor
        )
        let tunnelEnvironment = InMemoryEnvironment()
        let tunnel = ExtendedTunnel(
            tunnel: Tunnel(strategy: FakeTunnelStrategy(environment: tunnelEnvironment)),
            environment: tunnelEnvironment,
            processor: processor,
            interval: Constants.shared.tunnel.refreshInterval
        )
        let providerManager = ProviderManager(
            repository: InMemoryProviderRepository()
        )
        let migrationManager = MigrationManager()
        let preferencesManager = PreferencesManager()

        return AppContext(
            iapManager: iapManager,
            migrationManager: migrationManager,
            profileManager: profileManager,
            providerManager: providerManager,
            preferencesManager: preferencesManager,
            registry: registry,
            tunnel: tunnel,
            tunnelReceiptURL: BundleConfiguration.urlForBetaReceipt
        )
    }
}
