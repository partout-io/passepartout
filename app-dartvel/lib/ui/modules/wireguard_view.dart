// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Port of upstream `WireGuardView` and `WireGuardView.ConfigurationView`
// (app-apple/Sources/AppLibraryMain/Views/Modules/WireGuard).

import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../../platform/vpn_service.dart';
import '../kit.dart';
import 'module_view.dart';
import 'wireguard/wireguard_configuration.dart';
import 'wireguard/wireguard_import.dart';
import 'wireguard/wireguard_rows.dart';

/// Upstream `Strings.Unlocalized.Placeholders` for MTU and keep-alive.
const String _mtuPlaceholder = '1500';
const String _keepAlivePlaceholder = '30';

/// WireGuard module sections: the import button, then (when the module has a
/// configuration) interface, addresses/MTU, DNS, one section per peer and
/// "Add peer", in upstream's order.
List<Widget> wireGuardSections(BuildContext context, ModuleViewArgs args) {
  final configuration = WireGuardConfiguration(module: args.module);
  return <Widget>[
    WireGuardImportSection(args: args),
    if (configuration.hasConfiguration) ..._configurationSections(context, args, configuration),
  ];
}

List<Widget> _configurationSections(BuildContext context, ModuleViewArgs args, WireGuardConfiguration configuration) {
  final peers = configuration.peers;
  return <Widget>[
    // privateKeySection
    PSSection(header: tr(Strings.modulesWireguardInterface), children: <Widget>[
      WireGuardLongContentRow(
        title: tr(Strings.globalNounsPrivateKey),
        text: configuration.privateKey,
        onChanged: (text) => args.onChanged(WireGuardConfiguration(module: args.module).withPrivateKey(text)),
      ),
      WireGuardPublicKeyRow(privateKey: configuration.privateKey),
      PSRow(
        title: tr(Strings.modulesWireguardPrivateKeyGenerate),
        onTap: () => runGuarded(context, () async {
          final privateKey = await VpnService.instance.generateWireGuardKey();
          args.onChanged(WireGuardConfiguration(module: args.module).withPrivateKey(privateKey));
        }),
      ),
    ]),
    // interfaceSection
    PSSection(children: <Widget>[
      WireGuardLongContentRow(
        title: tr(Strings.globalNounsAddresses),
        text: configuration.addressesText,
        preview: asNumberOfEntries,
        keyboardType: TextInputType.url,
        onChanged: (text) => args.onChanged(WireGuardConfiguration(module: args.module).withAddresses(text)),
      ),
      PSTextRow(
        label: 'MTU',
        value: configuration.mtuText,
        placeholder: _mtuPlaceholder,
        keyboardType: TextInputType.number,
        onChanged: (text) => args.onChanged(WireGuardConfiguration(module: args.module).withMtu(text)),
      ),
    ]),
    // dnsSection
    PSSection(header: 'DNS', footer: tr(Strings.modulesWireguardInterfaceDnsFooter), children: <Widget>[
      WireGuardLongContentRow(
        title: tr(Strings.globalNounsServers),
        text: configuration.dnsServersText,
        preview: asNumberOfEntries,
        keyboardType: TextInputType.url,
        onChanged: (text) => args.onChanged(WireGuardConfiguration(module: args.module).withDnsServers(text)),
      ),
      WireGuardLongContentRow(
        title: tr(Strings.entitiesDnsSearchDomains),
        text: configuration.dnsDomainsText,
        preview: asNumberOfEntries,
        onChanged: (text) => args.onChanged(WireGuardConfiguration(module: args.module).withDnsDomains(text)),
      ),
    ]),
    // peerSections
    for (var index = 0; index < peers.length; index++) _peerSection(args, peers[index], index),
    // addPeerButton
    PSSection(children: <Widget>[
      Opacity(
        opacity: configuration.canAddPeer ? 1 : 0.4,
        child: PSRow(
          title: tr(Strings.modulesWireguardPeerAdd),
          onTap: configuration.canAddPeer ? () => args.onChanged(WireGuardConfiguration(module: args.module).addingPeer()) : null,
        ),
      ),
    ]),
  ];
}

Widget _peerSection(ModuleViewArgs args, WireGuardPeer peer, int index) {
  void edit(WireGuardPeer Function(WireGuardPeer peer) change) {
    final current = WireGuardConfiguration(module: args.module);
    args.onChanged(current.withPeer(index, change(current.peers[index])));
  }

  return PSSection(
    key: ValueKey<String>('wireguard-peer-$index'),
    header: tr(Strings.modulesWireguardPeer, <Object>[index + 1]),
    children: <Widget>[
      WireGuardLongContentRow(
        title: tr(Strings.globalNounsPublicKey),
        text: peer.publicKey,
        onChanged: (text) => edit((peer) => peer.withPublicKey(text)),
      ),
      WireGuardLongContentRow(
        title: tr(Strings.modulesWireguardPresharedKey),
        text: peer.preSharedKey,
        onChanged: (text) => edit((peer) => peer.withPreSharedKey(text)),
      ),
      WireGuardLongContentRow(
        title: tr(Strings.globalNounsEndpoint),
        text: peer.endpoint,
        onChanged: (text) => edit((peer) => peer.withEndpoint(text)),
      ),
      WireGuardLongContentRow(
        title: tr(Strings.modulesWireguardAllowedIps),
        text: peer.allowedIPsText,
        preview: asNumberOfEntries,
        keyboardType: TextInputType.url,
        onChanged: (text) => edit((peer) => peer.withAllowedIPs(text)),
      ),
      PSTextRow(
        label: tr(Strings.globalNounsKeepAlive),
        value: peer.keepAliveText,
        placeholder: _keepAlivePlaceholder,
        keyboardType: TextInputType.number,
        onChanged: (text) => edit((peer) => peer.withKeepAlive(text)),
      ),
      PSRow(
        title: tr(Strings.modulesWireguardPeerDelete),
        destructive: true,
        onTap: () => args.onChanged(WireGuardConfiguration(module: args.module).removingPeer(index)),
      ),
    ],
  );
}
