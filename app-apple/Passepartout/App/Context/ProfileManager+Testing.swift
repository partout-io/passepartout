// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import AppLibrary
import CommonLibrary

extension ProfileManager {
    public static func forUITesting(
        withNewModule newModule: @escaping (ModuleType) -> any ModuleBuilder,
        processor: ProfileProcessor,
        repository: ProfileRepository = InMemoryProfileRepository()
    ) -> ProfileManager {
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
                    var onDemandIdIfDisabled: UniqueID?

                    for moduleType in parameters.moduleTypes {
                        var moduleBuilder = newModule(moduleType)

                        if var wgBuilder = moduleBuilder as? WireGuardModule.Builder {
                            let gen = FakeWireGuardKeyGenerator()
                            var cfgBuilder = WireGuard.Configuration.Builder(keyGenerator: gen)
                            cfgBuilder.peers = [.init(publicKey: gen.newPrivateKey())]
                            wgBuilder.configurationBuilder = cfgBuilder
                            moduleBuilder = wgBuilder
                        } else if var onDemandBuilder = moduleBuilder as? OnDemandModule.Builder {
                            if parameters.name == "My VPS" {
                                onDemandIdIfDisabled = onDemandBuilder.id
                            }
                            onDemandBuilder.policy = .excluding
                            onDemandBuilder.withSSIDs = [
                                "Friend's House": false,
                                "My Home Network": true,
                                "Safe Wi-Fi": true
                            ]
                            moduleBuilder = onDemandBuilder
                        } else if var dnsBuilder = moduleBuilder as? DNSModule.Builder {
//                            dnsBuilder.protocolType = .https
//                            dnsBuilder.dohURL = "https://cloudflare-dns.com/dns-query"
                            dnsBuilder.protocolType = .cleartext
                            dnsBuilder.servers = ["1.1.1.1", "1.0.0.1"]
                            dnsBuilder.domains = ["my-domain.com", "search-one.com", "search-two.org"]
                            moduleBuilder = dnsBuilder
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

        init(_ name: String, _ isShared: Bool, _ isTV: Bool, _ moduleTypes: [ModuleType]) {
            self.name = name
            self.isShared = isShared
            self.isTV = isTV
            self.moduleTypes = moduleTypes
        }
    }

    static let mockParameters: [Parameters] = [
        Parameters("CloudFlare DoT", false, false, [.DNS]),
        Parameters("Coffee VPN", true, false, [.WireGuard]),
        Parameters("My VPS", true, true, [.WireGuard, .OnDemand, .DNS, .HTTPProxy]),
        Parameters("Office", true, true, [.OnDemand, .HTTPProxy]),
        Parameters("Personal DoH", false, false, [.DNS, .OnDemand])
    ]
}
