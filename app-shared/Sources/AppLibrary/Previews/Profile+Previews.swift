// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension Profile {
    public static let forPreviews: Profile = {
        var profile = Profile.Builder()
        profile.name = "Mock profile"
        do {
            var ovpn = OpenVPNModule.Builder()
            ovpn.configurationBuilder = OpenVPN.Configuration.Builder(withFallbacks: true)
            ovpn.configurationBuilder?.ca = .init(pem: "some CA")
            ovpn.configurationBuilder?.remotes = [
                try .init("1.2.3.4", .init(.udp, 80))
            ]
            profile.modules.append(try ovpn.build())

            var dns = DNSModule.Builder()
            dns.protocolType = .https
            dns.servers = ["1.1.1.1"]
            dns.dohURL = "https://1.1.1.1/dns-query"
            profile.modules.append(try dns.build())

            var proxy = HTTPProxyModule.Builder()
            proxy.address = "1.1.1.1"
            proxy.port = 1080
            proxy.secureAddress = "2.2.2.2"
            proxy.securePort = 8080
            proxy.bypassDomains = ["bypass.com"]
            profile.modules.append(try proxy.build())

            profile.activeModulesIds = [ovpn.id, dns.id]

            return try profile.build()
        } catch {
            fatalError("Unable to build: \(error)")
        }
    }()

    public static func newMockProfile(withName name: String? = nil) -> Profile {
        do {
            var copy = forPreviews.builder(withNewId: true)
            copy.name = name ?? String(copy.id.uuidString.prefix(8))
            return try copy.build()
        } catch {
            fatalError("Unable to build: \(error)")
        }
    }
}
