// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension DNSModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.dns]
    }
}

extension HTTPProxyModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.httpProxy]
    }
}

extension IPModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        [.routing]
    }
}

extension OnDemandModule.Builder: AppFeatureRequiring {
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

extension OpenVPNModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        var list: Set<ABI.AppFeature> = []
        if isInteractive, let otpMethod = credentials?.otpMethod, otpMethod != .none {
            list.insert(.otp)
        }
        return list
    }
}

extension WireGuardModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        []
    }
}

#if PSP_PROVIDERS
extension ProviderModule.Builder: AppFeatureRequiring {
    public var features: Set<ABI.AppFeature> {
        var list: Set<ABI.AppFeature> = []
        providerId?.features.forEach {
            list.insert($0)
        }
        return list
    }
}
#endif
