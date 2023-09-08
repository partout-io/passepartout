//
//  OnDemand+Rules.swift
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
import NetworkExtension
import PassepartoutCore
import PassepartoutVPN

extension NEOnDemandRuleInterfaceType {
    static var compatibleEthernet: NEOnDemandRuleInterfaceType? {
        #if targetEnvironment(macCatalyst)
        // XXX: Catalyst, missing enum case, try hardcoding
        // https://developer.apple.com/documentation/networkextension/neondemandruleinterfacetype/ethernet
        NEOnDemandRuleInterfaceType(rawValue: 1)
        #elseif os(macOS)
        .ethernet
        #else
        nil
        #endif
    }
}

extension VPNConfigurationParameters {
    var onDemandRules: [NEOnDemandRule] {
        profile.onDemand.rules(isInteractive: profile.account.authenticationMethod == .interactive, withCustomRules: withCustomRules)
    }
}

private extension Profile.OnDemand {
    func rules(isInteractive: Bool, withCustomRules: Bool) -> [NEOnDemandRule] {
        guard isEnabled && !isInteractive else {
            return []
        }

        var rules: [NEOnDemandRule] = []

        // apply exceptions (unless .any)
        if withCustomRules && policy != .any {
            if Utils.hasCellularData() && withMobileNetwork {
                rules.append(cellularRule())
            }
            if Utils.hasEthernet() && withEthernetNetwork {
                if let rule = ethernetRule() {
                    rules.append(rule)
                } else {
                    pp_log.warning("Unable to add rule for NEOnDemandRuleInterfaceType.ethernet (not compatible)")
                }
            }
            let SSIDs = Array(withSSIDs.filter { $1 }.keys)
            if !SSIDs.isEmpty {
                rules.append(wifiRule(SSIDs: SSIDs))
            }
        }

        // IMPORTANT: append fallback rule last
        rules.append(globalRule())

        return rules
    }
}

private extension Profile.OnDemand {
    func globalRule() -> NEOnDemandRule {
        let rule: NEOnDemandRule
        switch policy {
        case .any, .excluding:
            rule = NEOnDemandRuleConnect()

        case .including:
            rule = NEOnDemandRuleDisconnect()
        }
        rule.interfaceTypeMatch = .any
        return rule
    }

    func networkRule(matchingInterface interfaceType: NEOnDemandRuleInterfaceType) -> NEOnDemandRule {
        let rule: NEOnDemandRule
        switch policy {
        case .any, .excluding:
            rule = NEOnDemandRuleDisconnect()

        case .including:
            rule = NEOnDemandRuleConnect()
        }
        rule.interfaceTypeMatch = interfaceType
        return rule
    }

    func cellularRule() -> NEOnDemandRule {
        networkRule(matchingInterface: .cellular)
    }

    func ethernetRule() -> NEOnDemandRule? {
        guard let compatibleEthernet = NEOnDemandRuleInterfaceType.compatibleEthernet else {
            return nil
        }
        return networkRule(matchingInterface: compatibleEthernet)
    }

    func wifiRule(SSIDs: [String]) -> NEOnDemandRule {
        let rule = networkRule(matchingInterface: .wiFi)
        rule.ssidMatch = SSIDs
        return rule
    }
}
