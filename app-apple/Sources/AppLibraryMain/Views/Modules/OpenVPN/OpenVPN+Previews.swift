// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

// swiftlint: disable force_try
extension OpenVPN.Configuration.Builder {
    static var forPreviews: Self {
        var builder = OpenVPN.Configuration.Builder(withFallbacks: true)
        builder.noPullMask = [.proxy]
        builder.authUserPass = true
        builder.remotes = [
            .init(rawValue: "2.2.2.2:UDP:2222")!,
            .init(rawValue: "6.6.6.6:UDP:6666")!,
            .init(rawValue: "12.12.12.12:TCP:21212")!,
            .init(rawValue: "12:12:12:12:20:20:20:20:TCP6:21212")!
        ]
        builder.ipv4 = IPSettings(subnet: try! .init("5.5.5.5", 24))
            .including(routes: [
                .init(defaultWithGateway: .ip("120.1.1.1", .v4)),
                .init(.init(rawValue: "55.10.20.30/32"), nil)
            ])
            .excluding(routes: [
                .init(.init(rawValue: "88.40.30.30/32"), nil),
                .init(.init(rawValue: "60.60.60.60/32"), .ip("127.0.0.1", .v4))
            ])
        builder.ipv6 = IPSettings(subnet: try! .init("::5", 24))
            .including(routes: [
                .init(defaultWithGateway: .ip("120::1:1:1", .v6)),
                .init(.init(rawValue: "55:10:20::30/128"), nil),
                .init(.init(rawValue: "60:60:60::60/128"), .ip("::2", .v6))
            ])
            .excluding(routes: [
                .init(.init(rawValue: "88:40:30::30/32"), nil)
            ])
        builder.routingPolicies = [.IPv4, .IPv6]
        builder.dnsServers = ["1.2.3.4", "4.5.6.7"]
        builder.dnsDomain = "domain.com"
        builder.searchDomains = ["search1.com", "search2.com"]
        builder.httpProxy = try! .init("10.10.10.10", 1080)
        builder.httpsProxy = try! .init("10.10.10.10", 8080)
        builder.proxyAutoConfigurationURL = URL(string: "https://hello.pac")!
        builder.proxyBypassDomains = ["bypass1.com", "bypass2.com"]
        builder.xorMethod = .xormask(mask: .init(Data(hex: "1234")))
        builder.ca = .init(mockPem: "ca-certificate")
        builder.clientCertificate = .init(mockPem: "client-certificate")
        builder.clientKey = .init(mockPem: "client-key")
        builder.tlsWrap = .init(strategy: .auth, key: .init(biData: Data(count: 256)))
        builder.keepAliveInterval = 10.0
        builder.renegotiatesAfter = 60.0
        builder.randomizeEndpoint = true
        builder.randomizeHostnames = true
        return builder
    }
}
// swiftlint: enable force_try

private extension OpenVPN.CryptoContainer {
    init(mockPem: String) {
        self.init(pem: """
-----BEGIN CERTIFICATE-----
\(mockPem)
-----END CERTIFICATE-----
""")
    }
}
