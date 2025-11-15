// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout

extension DNSModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.dns]
    }
}

extension HTTPProxyModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.httpProxy]
    }
}

extension IPModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.routing]
    }
}

extension OnDemandModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
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

extension OpenVPNModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        var list: Set<ABI.AppFeature> = []
        if isInteractive, let otpMethod = credentials?.otpMethod, otpMethod != .none {
            list.insert(.otp)
        }
        return list
    }
}

extension ProviderModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        var list: Set<ABI.AppFeature> = []
        providerId?.features.forEach {
            list.insert($0)
        }
        return list
    }
}

extension WireGuardModule.Builder: ABI.AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        []
    }
}
