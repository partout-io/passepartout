//
//  Provider+Extensions.swift
//  Passepartout
//
//  Created by Davide De Rosa on 3/14/22.
//  Copyright (c) 2023 Davide De Rosa. All rights reserved.
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

import Foundation
import TunnelKitCore

extension Profile {
    public init(_ providerMetadata: ProviderMetadata, server: ProviderServer) {
        guard let vpnProtocol = server.presets?.first?.vpnProtocol else {
            fatalError("Server has no presets")
        }

        var provider = Provider(providerMetadata.name)
        var settings = Provider.Settings()
        settings.serverId = server.id
        settings.presetId = server.presetIds.first
        provider.vpnSettings[vpnProtocol] = settings

        self.init(name: providerMetadata.fullName, provider: provider)
    }

    public var providerName: String? {
        provider?.name
    }

    public func providerServerId() -> String? {
        provider?.vpnSettings[currentVPNProtocol]?.serverId
    }

    public mutating func setProviderServer(_ server: ProviderServer) {
        let oldServerId = provider?.vpnSettings[currentVPNProtocol]?.serverId
        provider?.vpnSettings[currentVPNProtocol]?.serverId = server.id
        provider?.vpnSettings[currentVPNProtocol]?.customEndpoint = nil

        // if server changed, pick first preset
        if server.id != oldServerId {
            provider?.vpnSettings[currentVPNProtocol]?.presetId = server.presetIds.first
        }
    }

    public func providerPreset(_ server: ProviderServer) -> ProviderServer.Preset? {
        guard let presetId = provider?.vpnSettings[currentVPNProtocol]?.presetId else {
            return nil
        }
        return server.preset(withId: presetId)
    }

    public mutating func setProviderPreset(_ preset: ProviderServer.Preset) {
        provider?.vpnSettings[currentVPNProtocol]?.presetId = preset.id
    }

    public func providerFavoriteLocationIds() -> Set<String>? {
        provider?.vpnSettings[currentVPNProtocol]?.favoriteLocationIds
    }

    public mutating func setProviderFavoriteLocationIds(_ ids: Set<String>?) {
        provider?.vpnSettings[currentVPNProtocol]?.favoriteLocationIds = ids
    }

    public func providerCustomEndpoint() -> Endpoint? {
        provider?.vpnSettings[currentVPNProtocol]?.customEndpoint
    }

    public mutating func setProviderCustomEndpoint(_ endpoint: Endpoint?) {
        provider?.vpnSettings[currentVPNProtocol]?.customEndpoint = endpoint
    }

    public func providerAccount() -> Profile.Account? {
        provider?.vpnSettings[currentVPNProtocol]?.account
    }

    public mutating func setProviderAccount(_ account: Profile.Account?) {
        provider?.vpnSettings[currentVPNProtocol]?.account = account
    }
}

extension Profile.Provider: ProfileSubtype {
    public var vpnProtocols: [VPNProtocolType] {
        Array(vpnSettings.keys)
    }
}
