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

/// The page of one long-content field (`ThemeLongContentLink`'s editor), at
/// `/profiles/<id>/modules/<moduleId>/<section>`: `private-key`, `addresses`,
/// `dns-servers`, `dns-domains`, and `peer-<n>-public-key`,
/// `peer-<n>-preshared-key`, `peer-<n>-endpoint`, `peer-<n>-allowed-ips`
/// (n counts from 1, as "Peer #n" does).
Widget? wireGuardSubpage(BuildContext context, ModuleViewArgs args, String section) {
  final field = _WireGuardField.parse(args, section);
  if (field == null) return null;
  return PSLongContentPage(
    title: field.title,
    text: field.text,
    keyboardType: field.keyboardType,
    onChanged: field.onChanged,
  );
}

/// One field edited on its own page: what its row shows and its page edits.
class const _WireGuardField({
  required final String section,
  required final String title,
  required final String text,
  required final ValueChanged<String> onChanged,
  final String? Function(String text)? preview,
  final TextInputType? keyboardType,
}) {
  /// The field [section] names in [args]' module, or null when there is none.
  static _WireGuardField? parse(ModuleViewArgs args, String section) {
    final configuration = WireGuardConfiguration(module: args.module);
    if (!configuration.hasConfiguration) return null;
    for (final field in _interfaceFields(args, configuration)) {
      if (field.section == section) return field;
    }
    final match = RegExp(r'^peer-(\d+)-').firstMatch(section);
    final peerNumber = match == null ? null : int.tryParse(match.group(1)!);
    final peers = configuration.peers;
    if (peerNumber == null || peerNumber < 1 || peerNumber > peers.length) return null;
    for (final field in _peerFields(args, peers[peerNumber - 1], peerNumber - 1)) {
      if (field.section == section) return field;
    }
    return null;
  }

  Widget row(ModuleViewArgs args) => PSLongContentRow(
        title: title,
        text: text,
        preview: preview,
        onTap: () => pushModuleSection(args, section),
      );
}

/// Edits go to the draft's current module: the args a page holds are rebuilt
/// on every draft change, so [ModuleViewArgs.module] is always the latest.
WireGuardConfiguration _current(ModuleViewArgs args) => WireGuardConfiguration(module: args.module);

List<_WireGuardField> _interfaceFields(ModuleViewArgs args, WireGuardConfiguration configuration) => <_WireGuardField>[
      _WireGuardField(
        section: 'private-key',
        title: tr(Strings.globalNounsPrivateKey),
        text: configuration.privateKey,
        onChanged: (text) => args.onChanged(_current(args).withPrivateKey(text)),
      ),
      _WireGuardField(
        section: 'addresses',
        title: tr(Strings.globalNounsAddresses),
        text: configuration.addressesText,
        preview: asNumberOfEntries,
        keyboardType: TextInputType.url,
        onChanged: (text) => args.onChanged(_current(args).withAddresses(text)),
      ),
      _WireGuardField(
        section: 'dns-servers',
        title: tr(Strings.globalNounsServers),
        text: configuration.dnsServersText,
        preview: asNumberOfEntries,
        keyboardType: TextInputType.url,
        onChanged: (text) => args.onChanged(_current(args).withDnsServers(text)),
      ),
      _WireGuardField(
        section: 'dns-domains',
        title: tr(Strings.entitiesDnsSearchDomains),
        text: configuration.dnsDomainsText,
        preview: asNumberOfEntries,
        onChanged: (text) => args.onChanged(_current(args).withDnsDomains(text)),
      ),
    ];

List<_WireGuardField> _peerFields(ModuleViewArgs args, WireGuardPeer peer, int index) {
  void edit(WireGuardPeer Function(WireGuardPeer peer) change) {
    final current = _current(args);
    if (index >= current.peers.length) return;
    args.onChanged(current.withPeer(index, change(current.peers[index])));
  }

  final prefix = 'peer-${index + 1}';
  return <_WireGuardField>[
    _WireGuardField(
      section: '$prefix-public-key',
      title: tr(Strings.globalNounsPublicKey),
      text: peer.publicKey,
      onChanged: (text) => edit((peer) => peer.withPublicKey(text)),
    ),
    _WireGuardField(
      section: '$prefix-preshared-key',
      title: tr(Strings.modulesWireguardPresharedKey),
      text: peer.preSharedKey,
      onChanged: (text) => edit((peer) => peer.withPreSharedKey(text)),
    ),
    _WireGuardField(
      section: '$prefix-endpoint',
      title: tr(Strings.globalNounsEndpoint),
      text: peer.endpoint,
      onChanged: (text) => edit((peer) => peer.withEndpoint(text)),
    ),
    _WireGuardField(
      section: '$prefix-allowed-ips',
      title: tr(Strings.modulesWireguardAllowedIps),
      text: peer.allowedIPsText,
      preview: asNumberOfEntries,
      keyboardType: TextInputType.url,
      onChanged: (text) => edit((peer) => peer.withAllowedIPs(text)),
    ),
  ];
}

List<Widget> _configurationSections(BuildContext context, ModuleViewArgs args, WireGuardConfiguration configuration) {
  final peers = configuration.peers;
  final interfaceFields = _interfaceFields(args, configuration);
  return <Widget>[
    // privateKeySection
    PSSection(header: tr(Strings.modulesWireguardInterface), children: <Widget>[
      interfaceFields[0].row(args),
      WireGuardPublicKeyRow(privateKey: configuration.privateKey),
      PSRow(
        title: tr(Strings.modulesWireguardPrivateKeyGenerate),
        onTap: () => runGuarded(context, () async {
          final privateKey = await VpnService.instance.generateWireGuardKey();
          args.onChanged(_current(args).withPrivateKey(privateKey));
        }),
      ),
    ]),
    // interfaceSection
    PSSection(children: <Widget>[
      interfaceFields[1].row(args),
      PSTextRow(
        label: 'MTU',
        value: configuration.mtuText,
        placeholder: _mtuPlaceholder,
        keyboardType: TextInputType.number,
        onChanged: (text) => args.onChanged(_current(args).withMtu(text)),
      ),
    ]),
    // dnsSection
    PSSection(header: 'DNS', footer: tr(Strings.modulesWireguardInterfaceDnsFooter), children: <Widget>[
      interfaceFields[2].row(args),
      interfaceFields[3].row(args),
    ]),
    // peerSections
    for (var index = 0; index < peers.length; index++) _peerSection(args, peers[index], index),
    // addPeerButton
    PSSection(children: <Widget>[
      Opacity(
        opacity: configuration.canAddPeer ? 1 : 0.4,
        child: PSRow(
          title: tr(Strings.modulesWireguardPeerAdd),
          onTap: configuration.canAddPeer ? () => args.onChanged(_current(args).addingPeer()) : null,
        ),
      ),
    ]),
  ];
}

Widget _peerSection(ModuleViewArgs args, WireGuardPeer peer, int index) => PSSection(
      key: ValueKey<String>('wireguard-peer-$index'),
      header: tr(Strings.modulesWireguardPeer, <Object>[index + 1]),
      children: <Widget>[
        for (final field in _peerFields(args, peer, index)) field.row(args),
        PSTextRow(
          label: tr(Strings.globalNounsKeepAlive),
          value: peer.keepAliveText,
          placeholder: _keepAlivePlaceholder,
          keyboardType: TextInputType.number,
          onChanged: (text) {
            final current = _current(args);
            args.onChanged(current.withPeer(index, current.peers[index].withKeepAlive(text)));
          },
        ),
        PSRow(
          title: tr(Strings.modulesWireguardPeerDelete),
          destructive: true,
          onTap: () => args.onChanged(_current(args).removingPeer(index)),
        ),
      ],
    );
