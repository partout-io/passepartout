//
//  PassepartoutVPN+StrippableContent.swift
//  Passepartout
//
//  Created by Davide De Rosa on 4/7/22.
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
import PassepartoutCore
import PassepartoutVPN

extension Profile.Account: StrippableContent {
    public var stripped: Self {
        Self(
            username.stripped,
            password.stripped
        )
    }
}

extension Profile.OnDemand: StrippableContent {
    public var stripped: Self {
        var copy = self
        copy.withSSIDs = copy.withSSIDs.reduce(into: [String: Bool]()) {
            guard let strippedKey = $1.key.strippedNotEmpty else {
                return
            }
            $0[strippedKey] = $1.value
        }
        return copy
    }
}

extension Profile.NetworkSettings: StrippableContent {
    public var stripped: Self {
        var copy = self
        copy.dns.dnsServers = copy.dns.dnsServers?.compactMap(\.strippedNotEmpty)
        copy.dns.dnsSearchDomains = copy.dns.dnsSearchDomains?.compactMap(\.strippedNotEmpty)
        copy.dns.dnsTLSServerName = copy.dns.dnsTLSServerName?.strippedNotEmpty
        copy.proxy.proxyAddress = copy.proxy.proxyAddress?.strippedNotEmpty
        copy.proxy.proxyBypassDomains = copy.proxy.proxyBypassDomains?.compactMap(\.strippedNotEmpty)
        return copy
    }
}
