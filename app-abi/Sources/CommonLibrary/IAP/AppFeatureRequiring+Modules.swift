// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation

extension DNSModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        [.dns]
    }
}

extension HTTPProxyModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        [.httpProxy]
    }
}

extension IPModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        [.routing]
    }
}

extension OnDemandModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        guard policy != .any else {
            return []
        }
        // empty rules require no purchase
        if !withMobileNetwork && !withEthernetNetwork && !withSSIDs.map(\.value).contains(true) {
            return []
        }
        return [.onDemand]
    }
}

extension OpenVPNModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        var list: Set<UI.AppFeature> = []
        if isInteractive, let otpMethod = credentials?.otpMethod, otpMethod != .none {
            list.insert(.otp)
        }
        return list
    }
}

extension ProviderModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        var list: Set<UI.AppFeature> = []
        providerId?.features.forEach {
            list.insert($0)
        }
        return list
    }
}

extension WireGuardModule.Builder: UI.AppFeatureRequiring {
    public var features: Set<UI.AppFeature> {
        []
    }
}
