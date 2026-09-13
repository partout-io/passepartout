// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

extension ModuleHandler {
    public static let allKnownHandlers: [ModuleHandler] = [
        DNSModule.moduleHandler,
        HTTPProxyModule.moduleHandler,
        IPModule.moduleHandler,
        OnDemandModule.moduleHandler,
        OpenVPNModule.moduleHandler,
        WireGuardModule.moduleHandler
    ]
}

@available(*, deprecated)
extension DNSModule {
    static let moduleHandler = ModuleHandler(.DNS, DNSModule.self)
}

@available(*, deprecated)
extension HTTPProxyModule {
    static let moduleHandler = ModuleHandler(.HTTPProxy, HTTPProxyModule.self)
}

@available(*, deprecated)
extension IPModule {
    static let moduleHandler = ModuleHandler(.IP, IPModule.self)
}

@available(*, deprecated)
extension OnDemandModule {
    static let moduleHandler = ModuleHandler(.OnDemand, OnDemandModule.self)
}

@available(*, deprecated)
extension OpenVPNModule {
    static let moduleHandler = ModuleHandler(.OpenVPN, OpenVPNModule.self)
}

@available(*, deprecated)
extension WireGuardModule {
    static let moduleHandler = ModuleHandler(.WireGuard, WireGuardModule.self)
}
