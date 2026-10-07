// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Port of upstream `WireGuardView.ConfigurationView.ViewModel` (load/save),
// working directly on the lossless `WireGuardModule` JSON of openapi.yaml.
//
// Upstream loads the configuration into comma-joined strings and writes the
// whole builder back on every change. Here every edit writes only the field
// it changes, so fields the editor does not show (listenPort, DNS protocol,
// unknown keys) survive untouched. Nulls are never written: an empty or
// invalid optional value removes its key, as upstream's `nil` does.

import '../../../domain/profile.dart';

/// Upstream's `separator` for list fields edited as one line of text.
const String wireGuardListSeparator = ',';

/// Upstream's `String.trimmedSplit(separator:)`, dropping empty entries.
List<String> wireGuardSplit(String text) => text
    .split(wireGuardListSeparator)
    .map((entry) => entry.trim())
    .where((entry) => entry.isNotEmpty)
    .toList();

/// UInt16 parse, as Swift's `UInt16(String)`: null when not a valid value.
int? parseUInt16(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value < 0 || value > 65535) return null;
  return value;
}

/// Read and edit one `WireGuardModule` value.
class const WireGuardConfiguration({required final TaggedModule module}) {
  Map<String, dynamic> get _value => module.value;

  bool get hasConfiguration => _value['configuration'] is Map;

  Map<String, dynamic> get _configuration =>
      Map<String, dynamic>.from((_value['configuration'] as Map?) ?? const <String, dynamic>{});

  Map<String, dynamic> get _interface =>
      Map<String, dynamic>.from((_configuration['interface'] as Map?) ?? const <String, dynamic>{});

  Map<String, dynamic>? get _dns {
    final dns = _interface['dns'];
    return dns is Map ? Map<String, dynamic>.from(dns) : null;
  }

  // MARK: Interface

  String get privateKey => (_interface['privateKey'] as String?) ?? '';

  List<String> get addresses => _strings(_interface['addresses']);

  String get addressesText => addresses.join(wireGuardListSeparator);

  String get mtuText => _interface['mtu']?.toString() ?? '';

  List<String> get dnsServers => _strings(_dns?['servers']);

  String get dnsServersText => dnsServers.join(wireGuardListSeparator);

  /// Upstream's `DNSModule.builder().domains`: the primary domain first, then
  /// the search domains, without repeating the primary one.
  List<String> get dnsDomains {
    final dns = _dns;
    if (dns == null) return const <String>[];
    final domainName = dns['domainName'] as String?;
    final searchDomains = _strings(dns['searchDomains']);
    if (domainName == null) return searchDomains;
    if (searchDomains.isNotEmpty && searchDomains.first == domainName) return searchDomains;
    return <String>[domainName, ...searchDomains];
  }

  String get dnsDomainsText => dnsDomains.join(wireGuardListSeparator);

  // MARK: Peers

  List<WireGuardPeer> get peers => <WireGuardPeer>[
        for (final peer in (_configuration['peers'] as List?) ?? const <dynamic>[])
          WireGuardPeer(json: Map<String, dynamic>.from(peer as Map)),
      ];

  /// Upstream disables "Add peer" while a peer with an empty public key exists.
  bool get canAddPeer => !peers.any((peer) => peer.publicKey.isEmpty);

  // MARK: Edits

  TaggedModule _withConfiguration(Map<String, dynamic> configuration) =>
      module.withField('configuration', configuration);

  TaggedModule _withInterface(Map<String, dynamic> interface) => _withConfiguration(<String, dynamic>{
        ..._configuration,
        'interface': interface,
        'peers': _configuration['peers'] ?? <dynamic>[],
      });

  TaggedModule _withInterfaceField(String key, Object? newValue) {
    final interface = _interface;
    if (newValue == null) {
      interface.remove(key);
    } else {
      interface[key] = newValue;
    }
    interface.putIfAbsent('privateKey', () => '');
    interface.putIfAbsent('addresses', () => <dynamic>[]);
    return _withInterface(interface);
  }

  /// Upstream only writes a private key that is not blank.
  TaggedModule withPrivateKey(String text) =>
      text.trim().isEmpty ? module : _withInterfaceField('privateKey', text.trim());

  TaggedModule withAddresses(String text) => _withInterfaceField('addresses', wireGuardSplit(text));

  TaggedModule withMtu(String text) => _withInterfaceField('mtu', parseUInt16(text));

  /// Empty servers discard the DNS settings (the section's footer says so).
  TaggedModule withDnsServers(String text) {
    final servers = wireGuardSplit(text);
    if (servers.isEmpty) return _withInterfaceField('dns', null);
    final dns = _dns ??
        <String, dynamic>{
          'id': newUniqueId(),
          'protocolType': <String, dynamic>{'type': 'cleartext'},
          if (dnsDomains.isNotEmpty) 'searchDomains': dnsDomains,
        };
    dns['servers'] = servers;
    return _withInterfaceField('dns', dns);
  }

  /// Domains are only kept with servers, as upstream's save does. Editing the
  /// list replaces the primary domain too (upstream: `isFirstDomainPrimary`
  /// false), since the list shown already includes it.
  TaggedModule withDnsDomains(String text) {
    final dns = _dns;
    if (dns == null) return module;
    final domains = wireGuardSplit(text);
    dns.remove('domainName');
    if (domains.isEmpty) {
      dns.remove('searchDomains');
    } else {
      dns['searchDomains'] = domains;
    }
    return _withInterfaceField('dns', dns);
  }

  TaggedModule _withPeers(List<WireGuardPeer> peers) => _withConfiguration(<String, dynamic>{
        ..._configuration,
        'interface': _configuration['interface'] ?? <String, dynamic>{'privateKey': '', 'addresses': <dynamic>[]},
        'peers': peers.map((peer) => peer.json).toList(),
      });

  TaggedModule withPeer(int index, WireGuardPeer peer) => _withPeers(peers..[index] = peer);

  TaggedModule addingPeer() => canAddPeer ? _withPeers(peers..add(WireGuardPeer.empty())) : module;

  TaggedModule removingPeer(int index) => _withPeers(peers..removeAt(index));

  /// Upstream's import: the module keeps its id and takes the imported configuration.
  TaggedModule importing(TaggedModule imported) {
    final configuration = imported.value['configuration'];
    if (imported.type != ModuleType.wireGuard || configuration is! Map) {
      throw const FormatException('Not a WireGuard configuration');
    }
    return _withConfiguration(Map<String, dynamic>.from(configuration));
  }
}

/// One `WireGuard.RemoteInterface`.
class const WireGuardPeer({required final Map<String, dynamic> json}) {
  // Not const: the map is edited in place by the peer list helpers' copies.
  // ignore: prefer_const_constructors
  factory WireGuardPeer.empty() => WireGuardPeer(json: <String, dynamic>{'publicKey': '', 'allowedIPs': <dynamic>[]});

  String get publicKey => (json['publicKey'] as String?) ?? '';

  String get preSharedKey => (json['preSharedKey'] as String?) ?? '';

  /// Shown in wg-quick form: IPv6 hosts in brackets (upstream `wgRepresentation`).
  String get endpoint {
    final raw = (json['endpoint'] as String?) ?? '';
    final separator = raw.lastIndexOf(':');
    if (raw.startsWith('[') || separator < 0) return raw;
    final host = raw.substring(0, separator);
    return host.contains(':') ? '[$host]${raw.substring(separator)}' : raw;
  }

  List<String> get allowedIPs => _strings(json['allowedIPs']);

  String get allowedIPsText => allowedIPs.join(wireGuardListSeparator);

  String get keepAliveText => json['keepAlive']?.toString() ?? '';

  WireGuardPeer _with(String key, Object? newValue) {
    final next = <String, dynamic>{...json};
    if (newValue == null) {
      next.remove(key);
    } else {
      next[key] = newValue;
    }
    return WireGuardPeer(json: next);
  }

  WireGuardPeer withPublicKey(String text) => _with('publicKey', text.trim());

  WireGuardPeer withPreSharedKey(String text) => _with('preSharedKey', text.trim().isEmpty ? null : text.trim());

  WireGuardPeer withEndpoint(String text) => _with('endpoint', text.trim().isEmpty ? null : text.trim());

  WireGuardPeer withAllowedIPs(String text) => _with('allowedIPs', wireGuardSplit(text));

  WireGuardPeer withKeepAlive(String text) => _with('keepAlive', parseUInt16(text));
}

List<String> _strings(Object? value) =>
    value is List ? value.map((entry) => '$entry').toList() : const <String>[];
