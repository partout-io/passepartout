// SPDX-FileCopyrightText: 2026 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import CommonLibrary
import SwiftUI

extension WireGuardView {
    struct ConfigurationView: View {

        @ObservedObject
        private var draft: ModuleDraft<WireGuardModule.Builder>

        @Binding
        private var viewModel: ViewModel

        private let keyGenerator: WireGuardKeyGenerator?

        private var configurationBuilder: WireGuard.Configuration.Builder {
            draft.module.configurationBuilder ?? newConfiguration
        }

        private let newConfiguration: WireGuard.Configuration.Builder

        init(
            draft: ModuleDraft<WireGuardModule.Builder>,
            viewModel: Binding<ViewModel>,
            keyGenerator: WireGuardKeyGenerator?
        ) {
            self.draft = draft
            _viewModel = viewModel
            self.keyGenerator = keyGenerator
            newConfiguration = keyGenerator.map {
                WireGuard.Configuration.Builder(keyGenerator: $0)
            } ?? WireGuard.Configuration.Builder(privateKey: "")
        }

        var body: some View {
            Group {
                privateKeySection
                interfaceSection
                dnsSection
                peerSections
                Section {
                    ThemeTrailingContent(content: addPeerButton)
                }
            }
            .onChange(of: viewModel) {
                $0.save(to: draft, fallback: newConfiguration)
            }
        }
    }
}

private extension WireGuardView.ConfigurationView {
    var privateKeySection: some View {
        themeModuleSection(header: Strings.Modules.Wireguard.interface) {
            ThemeLongContentLink(
                Strings.Global.Nouns.privateKey,
                text: $viewModel.privateKey
            )
            if let keyGenerator {
                ThemeCopiableText(
                    Strings.Global.Nouns.publicKey,
                    value: (try? keyGenerator.publicKey(for: viewModel.privateKey)) ?? ""
                )
                Button(Strings.Modules.Wireguard.PrivateKey.generate) {
                    viewModel.privateKey = keyGenerator.newPrivateKey()
                }
            }
        }
    }

    var interfaceSection: some View {
        themeModuleSection(header: nil) {
            ThemeLongContentLink(
                Strings.Global.Nouns.addresses,
                text: $viewModel.addresses,
                inputType: .ipAddress,
                preview: \.asNumberOfEntries
            )
            ThemeTextField(
                Strings.Unlocalized.mtu,
                text: $viewModel.mtu,
                placeholder: Strings.Unlocalized.Placeholders.mtu,
                inputType: .number
            )
        }
    }

    var dnsSection: some View {
        themeModuleSection(header: Strings.Unlocalized.dns) {
            ThemeLongContentLink(
                Strings.Global.Nouns.servers,
                text: $viewModel.dnsServers,
                inputType: .ipAddress,
                preview: \.asNumberOfEntries
            )
            ThemeTextField(
                Strings.Global.Nouns.domain,
                text: $viewModel.dnsDomain,
                placeholder: Strings.Unlocalized.Placeholders.hostname
            )
            ThemeLongContentLink(
                Strings.Entities.Dns.searchDomains,
                text: $viewModel.dnsSearchDomains,
                preview: \.asNumberOfEntries
            )
        }
    }

    var peerSections: some View {
        ForEach(Array(zip(viewModel.peersOrder.indices, viewModel.peersOrder)), id: \.1) { index, publicKey in
            peerSection(for: publicKey, at: index)
        }
    }

    func peerSection(for publicKey: String, at index: Int) -> some View {
        themeModuleSection(header: Strings.Modules.Wireguard.peer(index + 1)) {
            let peerBinding = peerBinding(with: publicKey)

            ThemeLongContentLink(
                Strings.Global.Nouns.publicKey,
                text: peerBinding.publicKey
            )
            ThemeLongContentLink(
                Strings.Modules.Wireguard.presharedKey,
                text: peerBinding.preSharedKey
            )
            ThemeLongContentLink(
                Strings.Global.Nouns.endpoint,
                text: peerBinding.endpoint
            )
            ThemeLongContentLink(
                Strings.Modules.Wireguard.allowedIps,
                text: peerBinding.allowedIPs,
                inputType: .ipAddress,
                preview: \.asNumberOfEntries
            )
            ThemeTextField(
                Strings.Global.Nouns.keepAlive,
                text: peerBinding.keepAlive,
                placeholder: Strings.Unlocalized.Placeholders.keepAlive,
                inputType: .number
            )
            ThemeTrailingContent {
                removePeerButton(at: index, publicKey: publicKey)
            }
        }
    }

    func addPeerButton() -> some View {
        Button(Strings.Modules.Wireguard.Peer.add) {
            let newPeer = ViewModel.Peer()
            assert(newPeer.publicKey == "")
            withAnimation {
                viewModel.peers[newPeer.publicKey] = newPeer
                viewModel.peersOrder.append(newPeer.publicKey)
            }
        }
        .disabled(viewModel.peers[""] != nil)
    }

    func removePeerButton(at index: Int, publicKey: String) -> some View {
        Button(Strings.Modules.Wireguard.Peer.delete, role: .destructive) {
            withAnimation {
                viewModel.peersOrder.remove(at: index)
                viewModel.peers.removeValue(forKey: publicKey)
            }
        }
    }
}

private extension WireGuardView.ConfigurationView {
    var dnsRows: [Any?] {
        [
            configurationBuilder.interface.dns.servers.nilIfEmpty,
            configurationBuilder.interface.dns.domainName,
            configurationBuilder.interface.dns.searchDomains?.nilIfEmpty
        ]
    }
}

// MARK: - Logic

extension WireGuardView.ConfigurationView {

    @MainActor
    struct ViewModel: Equatable {
        struct Peer: Equatable {
            var publicKey = ""

            var preSharedKey = ""

            var endpoint = ""

            var allowedIPs = ""

            var keepAlive = ""
        }

        private let separator = ","

        var privateKey = ""

        var addresses = ""

        var mtu = ""

        var dnsServers = ""

        var dnsDomain = ""

        var dnsSearchDomains = ""

        var peers: [String: Peer] = [:]

        var peersOrder: [String] = []

        mutating func load(from configuration: WireGuard.Configuration.Builder) {
            privateKey = configuration.interface.privateKey
            addresses = configuration.interface.addresses.joined(separator: separator)
            mtu = configuration.interface.mtu?.description ?? ""

            dnsServers = configuration.interface.dns.servers.joined(separator: separator)
            dnsDomain = configuration.interface.dns.domainName ?? ""
            dnsSearchDomains = configuration.interface.dns.searchDomains?.joined(separator: separator) ?? ""

            peers = configuration.peers.reduce(into: [:]) {
                var peer = Peer()
                peer.publicKey = $1.publicKey
                peer.preSharedKey = $1.preSharedKey ?? ""
                peer.endpoint = $1.endpoint ?? ""
                peer.allowedIPs = $1.allowedIPs.joined(separator: separator)
                peer.keepAlive = $1.keepAlive?.description ?? ""
                $0[$1.publicKey] = peer
            }
            peersOrder = configuration.peers.map(\.publicKey)
        }

        func save(
            to draft: ModuleDraft<WireGuardModule.Builder>,
            fallback: WireGuard.Configuration.Builder
        ) {
            var configuration = draft.module.configurationBuilder ?? fallback
            configuration.interface.privateKey = privateKey
            configuration.interface.addresses = addresses.trimmedSplit(separator: separator)
            configuration.interface.mtu = UInt16(mtu)

            var dns = DNSModule.Builder()
            dns.servers = dnsServers.trimmedSplit(separator: separator)
            dns.domainName = dnsDomain
            dns.searchDomains = dnsSearchDomains.trimmedSplit(separator: separator)
            configuration.interface.dns = dns

            configuration.peers = peersOrder
                .compactMap {
                    guard let model = peers[$0] else {
                        return nil
                    }
                    var peer = WireGuard.RemoteInterface.Builder(publicKey: model.publicKey)
                    peer.preSharedKey = model.preSharedKey
                    peer.endpoint = model.endpoint
                    peer.allowedIPs = model.allowedIPs.trimmedSplit(separator: separator)
                    peer.keepAlive = UInt16(model.keepAlive)
                    return peer
                }

            draft.module.configurationBuilder = configuration
        }
    }
}

private extension WireGuardView.ConfigurationView {
    func peerBinding(with publicKey: String) -> Binding<ViewModel.Peer> {
        Binding {
            viewModel.peers[publicKey] ?? ViewModel.Peer()
        } set: {
            viewModel.peers[publicKey] = $0
        }
    }
}

private extension String {
    var asNumberOfEntries: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        let count = 1 + trimmed.ranges(of: ",").count
        return count.localizedEntries
    }
}

// MARK: - Previews

#Preview {
    struct Preview: View {

        @State
        private var module = WireGuardModule.Builder(configurationBuilder: .forPreviews)

        @State
        private var viewModel = WireGuardView.ConfigurationView.ViewModel()

        var body: some View {
            NavigationStack {
                Form {
                    WireGuardView.ConfigurationView(
                        draft: ModuleDraft(module: module),
                        viewModel: $viewModel,
                        keyGenerator: nil
                    )
                    .onLoad {
                        viewModel.load(from: module.configurationBuilder!)
                    }
                }
                .themeForm()
                .withMockEnvironment()
            }
        }
    }

    return Preview()
}
