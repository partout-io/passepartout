// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import Foundation

extension ProfileManager {
    public static func forUITesting(withRegistry registry: Registry, processor: ProfileProcessor) -> ProfileManager {
        let repository = InMemoryProfileRepository()
        let remoteRepository = InMemoryProfileRepository()
        let manager = ProfileManager(processor: processor, repository: repository)

        Task {
            do {
                try await manager.observeLocal()
                try await manager.observeRemote(repository: remoteRepository)

                for parameters in mockParameters {
                    var builder = Profile.Builder()
                    builder.name = parameters.name
                    builder.attributes.isAvailableForTV = parameters.isTV
                    var onDemandIdIfDisabled: UUID?

                    for moduleType in parameters.moduleTypes {
                        var moduleBuilder = moduleType.newModule(with: registry)

                        if parameters.name == "Hide.me" {
                            if var ovpnBuilder = moduleBuilder as? ProviderModule.Builder {
                                ovpnBuilder.providerId = parameters.providerId
                                ovpnBuilder.providerModuleType = .openVPN
                                ovpnBuilder.entity = mockHideMeEntity
                                let credentials = OpenVPN.Credentials.Builder(username: "foo", password: "bar").build()
                                var options = OpenVPNProviderTemplate.Options()
                                options.credentials = credentials
                                try ovpnBuilder.setOptions(options, for: moduleType)
                                moduleBuilder = ovpnBuilder
                            } else if var onDemandBuilder = moduleBuilder as? OnDemandModule.Builder {
#if os(tvOS)
                                onDemandIdIfDisabled = onDemandBuilder.id
#endif
                                onDemandBuilder.policy = .excluding
                                onDemandBuilder.withSSIDs = [
                                    "Friend's House": false,
                                    "My Home Network": true,
                                    "Safe Wi-Fi": true
                                ]
                                moduleBuilder = onDemandBuilder
                            } else if var dnsBuilder = moduleBuilder as? DNSModule.Builder {
                                dnsBuilder.protocolType = .https
                                dnsBuilder.dohURL = "https://cloudflare-dns.com/dns-query"
                                dnsBuilder.servers = ["1.1.1.1", "1.0.0.1"]
                                dnsBuilder.domainName = "my-domain.com"
                                dnsBuilder.searchDomains = ["search-one.com", "search-two.org"]
                                moduleBuilder = dnsBuilder
                            }
                        }

                        if parameters.name == "My VPS" {
                            if var ovpnBuilder = moduleBuilder as? OpenVPNModule.Builder {
                                var cfgBuilder = OpenVPN.Configuration.Builder()
                                cfgBuilder.ca = .init(pem: "...")
                                cfgBuilder.remotes = [
                                    ExtendedEndpoint(rawValue: "1.2.3.4:UDP:1234")!
                                ]
                                ovpnBuilder.configurationBuilder = cfgBuilder
                                moduleBuilder = ovpnBuilder
                            } else if let onDemandBuilder = moduleBuilder as? OnDemandModule.Builder {
                                moduleBuilder = onDemandBuilder
                            }
                        }

                        if var wgBuilder = moduleBuilder as? WireGuardModule.Builder {
                            var cfgBuilder = WireGuard.Configuration.Builder(privateKey: "")
                            cfgBuilder.peers = [.init(publicKey: "")]
                            wgBuilder.configurationBuilder = cfgBuilder
                            moduleBuilder = wgBuilder
                        }

                        let module = try moduleBuilder.build()
                        builder.modules.append(module)
                    }
                    builder.activateAllModules()

                    if let onDemandIdIfDisabled {
                        builder.activeModulesIds.remove(onDemandIdIfDisabled)
                    }

                    let profile = try builder.build()
                    try await manager.save(profile, isLocal: true, remotelyShared: parameters.isShared)
                }
            } catch {
                pspLog(.profiles, .error, "Unable to build ProfileManager for UI testing: \(error)")
            }
        }

        return manager
    }
}

private extension ProfileManager {
    struct Parameters {
        let name: String

        let isShared: Bool

        let isTV: Bool

        let moduleTypes: [ModuleType]

        let providerId: ProviderID?

        init(_ name: String, _ isShared: Bool, _ isTV: Bool, _ moduleTypes: [ModuleType], _ providerId: ProviderID? = nil) {
            self.name = name
            self.isShared = isShared
            self.isTV = isTV
            self.moduleTypes = moduleTypes
            self.providerId = providerId
        }
    }

    static let mockParameters: [Parameters] = [
        Parameters("CloudFlare DoT", false, false, [.dns]),
        Parameters("Coffee VPN", true, false, [.wireGuard, .onDemand]),
        Parameters("Hide.me", true, true, [.provider, .onDemand, .dns], .hideme),
        Parameters("My VPS", true, true, [.openVPN, .onDemand]),
        Parameters("Office", true, false, [.onDemand, .httpProxy]),
        Parameters("Personal DoH", false, false, [.dns, .onDemand])
    ]

    static var mockHideMeEntity: ProviderEntity {
        do {
            var cfgBuilder = OpenVPN.Configuration.Builder()
            cfgBuilder.ca = .init(pem: "...")
            let cfg = try cfgBuilder.build(isClient: false)
            let endpoints: [EndpointProtocol] = [.init(.udp, 1194)]
            let template = OpenVPNProviderTemplate(configuration: cfg, endpoints: endpoints)
            let templateData = try JSONEncoder().encode(template)

            let preset = ProviderPreset(
                providerId: .hideme,
                presetId: "default",
                description: "Default",
                moduleType: .openVPN,
                templateData: templateData
            )

            return ProviderEntity(
                server: .init(
                    metadata: .init(
                        providerId: .hideme,
                        categoryName: "default",
                        countryCode: "BE",
                        otherCountryCodes: nil,
                        area: nil
                    ),
                    serverId: "be-v4",
                    hostname: "be-v4.hideservers.net",
                    ipAddresses: nil,
                    supportedModuleTypes: [.openVPN],
                    supportedPresetIds: nil
                ),
                preset: preset,
                heuristic: .sameCountry("BE")
            )
        } catch {
            fatalError("Unable to build Hide.me entity: \(error)")
        }
    }
}
