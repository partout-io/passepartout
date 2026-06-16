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
                amneziaSection
                peerSections
                Section {
                    ThemeTrailingContent(content: addPeerButton)
                }
            }
            .onChange(of: viewModel) {
                $1.save(to: draft, fallback: newConfiguration)
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
                inputType: .number,
                sideAligned: true
            )
        }
    }

    var amneziaSection: some View {
        themeModuleSection(header: Strings.Unlocalized.amneziaWG) {
            ThemeTextField("Jc", text: $viewModel.awgJc, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("Jmin", text: $viewModel.awgJmin, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("Jmax", text: $viewModel.awgJmax, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("S1", text: $viewModel.awgS1, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("S2", text: $viewModel.awgS2, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("S3", text: $viewModel.awgS3, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("S4", text: $viewModel.awgS4, placeholder: "0", inputType: .number, sideAligned: true)
            ThemeTextField("H1", text: $viewModel.awgH1, placeholder: "", inputType: .number, sideAligned: true)
            ThemeTextField("H2", text: $viewModel.awgH2, placeholder: "", inputType: .number, sideAligned: true)
            ThemeTextField("H3", text: $viewModel.awgH3, placeholder: "", inputType: .number, sideAligned: true)
            ThemeTextField("H4", text: $viewModel.awgH4, placeholder: "", inputType: .number, sideAligned: true)
            ThemeTextField("I1", text: $viewModel.awgI1, placeholder: "", sideAligned: true)
            ThemeTextField("I2", text: $viewModel.awgI2, placeholder: "", sideAligned: true)
            ThemeTextField("I3", text: $viewModel.awgI3, placeholder: "", sideAligned: true)
            ThemeTextField("I4", text: $viewModel.awgI4, placeholder: "", sideAligned: true)
            ThemeTextField("I5", text: $viewModel.awgI5, placeholder: "", sideAligned: true)
        }
    }

    var dnsSection: some View {
        themeModuleSection(
            header: Strings.Unlocalized.dns,
            footer: Strings.Modules.Wireguard.Interface.Dns.footer
        ) {
            ThemeLongContentLink(
                Strings.Global.Nouns.servers,
                text: $viewModel.dnsServers,
                inputType: .ipAddress,
                preview: \.asNumberOfEntries
            )
            ThemeLongContentLink(
                Strings.Entities.Dns.searchDomains,
                text: $viewModel.dnsDomains,
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
            configurationBuilder.interface.dns?.servers.nilIfEmpty,
            configurationBuilder.interface.dns?.domains?.nilIfEmpty
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

        var dnsDomains = ""

        var awgJc = ""
        var awgJmin = ""
        var awgJmax = ""
        var awgS1 = ""
        var awgS2 = ""
        var awgS3 = ""
        var awgS4 = ""
        var awgH1 = ""
        var awgH2 = ""
        var awgH3 = ""
        var awgH4 = ""
        var awgI1 = ""
        var awgI2 = ""
        var awgI3 = ""
        var awgI4 = ""
        var awgI5 = ""

        var peers: [String: Peer] = [:]

        var peersOrder: [String] = []

        mutating func load(from configuration: WireGuard.Configuration.Builder) {
            privateKey = configuration.interface.privateKey
            addresses = configuration.interface.addresses.joined(separator: separator)
            mtu = configuration.interface.mtu?.description ?? ""

            dnsServers = configuration.interface.dns?.servers.joined(separator: separator) ?? ""
            dnsDomains = configuration.interface.dns?.domains?.joined(separator: separator) ?? ""

            if let awg = configuration.interface.amneziaParameters {
                awgJc = awg.jc?.description ?? ""
                awgJmin = awg.jmin?.description ?? ""
                awgJmax = awg.jmax?.description ?? ""
                awgS1 = awg.s1?.description ?? ""
                awgS2 = awg.s2?.description ?? ""
                awgS3 = awg.s3?.description ?? ""
                awgS4 = awg.s4?.description ?? ""
                awgH1 = awg.h1 ?? ""
                awgH2 = awg.h2 ?? ""
                awgH3 = awg.h3 ?? ""
                awgH4 = awg.h4 ?? ""
                awgI1 = awg.i1 ?? ""
                awgI2 = awg.i2 ?? ""
                awgI3 = awg.i3 ?? ""
                awgI4 = awg.i4 ?? ""
                awgI5 = awg.i5 ?? ""
            }

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
            if !privateKey.trimmingCharacters(in: .whitespaces).isEmpty {
                configuration.interface.privateKey = privateKey
            }
            configuration.interface.addresses = addresses.trimmedSplit(separator: separator)
            configuration.interface.mtu = UInt16(mtu)

            let servers = dnsServers.trimmedSplit(separator: separator)
            let domains = dnsDomains.trimmedSplit(separator: separator)
            if !servers.isEmpty {
                configuration.interface.dns = DNSModule.Builder(
                    servers: servers,
                    domains: domains
                )
            } else {
                configuration.interface.dns = nil
            }

            let awgFields: [String] = [awgJc, awgJmin, awgJmax, awgS1, awgS2, awgS3, awgS4, awgH1, awgH2, awgH3, awgH4, awgI1, awgI2, awgI3, awgI4, awgI5]
            if awgFields.contains(where: { !$0.isEmpty }) {
                var awg = WireGuard.AmneziaParameters.Builder()
                awg.jc = UInt16(awgJc)
                awg.jmin = UInt16(awgJmin)
                awg.jmax = UInt16(awgJmax)
                awg.s1 = UInt16(awgS1)
                awg.s2 = UInt16(awgS2)
                awg.s3 = UInt16(awgS3)
                awg.s4 = UInt16(awgS4)
                awg.h1 = awgH1.isEmpty ? nil : (UInt32(awgH1) != nil ? awgH1 : nil)
                awg.h2 = awgH2.isEmpty ? nil : (UInt32(awgH2) != nil ? awgH2 : nil)
                awg.h3 = awgH3.isEmpty ? nil : (UInt32(awgH3) != nil ? awgH3 : nil)
                awg.h4 = awgH4.isEmpty ? nil : (UInt32(awgH4) != nil ? awgH4 : nil)
                awg.i1 = awgI1.isEmpty ? nil : awgI1
                awg.i2 = awgI2.isEmpty ? nil : awgI2
                awg.i3 = awgI3.isEmpty ? nil : awgI3
                awg.i4 = awgI4.isEmpty ? nil : awgI4
                awg.i5 = awgI5.isEmpty ? nil : awgI5
                configuration.interface.amneziaParameters = awg
            } else {
                configuration.interface.amneziaParameters = nil
            }

            configuration.peers = peersOrder
                .compactMap {
                    guard let model = peers[$0] else {
                        return nil
                    }
                    var peer = WireGuard.RemoteInterface.Builder(publicKey: model.publicKey)
                    if !model.preSharedKey.trimmingCharacters(in: .whitespaces).isEmpty {
                        peer.preSharedKey = model.preSharedKey
                    }
                    if !model.endpoint.trimmingCharacters(in: .whitespaces).isEmpty {
                        peer.endpoint = model.endpoint
                    }
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
