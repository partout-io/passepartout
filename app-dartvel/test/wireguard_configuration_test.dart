// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// WireGuard editor logic against the real Partout engine. Fixtures adapted
// from partout/tests/wireguard/parser.zig, copyright Davide De Rosa.
// Run with PARTOUT_LIBRARY and LD_LIBRARY_PATH set (see docs/BUILD.md).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/platform/vpn_service.dart';
import 'package:passepartout/platform/vpn_service_native.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_configuration.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_import.dart';

const String fullConf = '''
[Interface]
PrivateKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
ListenPort = 51820
Address = 10.8.0.6/24, fd00::1/64
DNS = 1.1.1.1, example.com
MTU = 1420

[Peer]
PublicKey = muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=
PresharedKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = [1:2:3::4]:12345
PersistentKeepalive = 25
''';

const String repeatedKeysConf = '''
[Interface]
PrivateKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
Address = 10.8.0.6/24
Address = fd00::1/64
DNS = 1.1.1.1
DNS = example.com
[Peer]
PublicKey = muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=
AllowedIPs = 0.0.0.0/0
AllowedIPs = ::/0
''';

const String hostnameConf = '''
[Interface]
PrivateKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=
AllowedIPs = 0.0.0.0/0
Endpoint = wg.example.com:51820
''';

/// Every key a value tree carries, with its path, to assert nothing is lost.
Set<String> keyPaths(Object? value, [String prefix = '']) => switch (value) {
      Map() => <String>{
          for (final entry in value.entries) ...<String>{
            '$prefix${entry.key}',
            ...keyPaths(entry.value, '$prefix${entry.key}.'),
          },
        },
      List() => <String>{for (var i = 0; i < value.length; i++) ...keyPaths(value[i], '$prefix$i.')},
      _ => const <String>{},
    };

bool hasNull(Object? value) => switch (value) {
      null => true,
      Map() => value.values.any(hasNull),
      List() => value.any(hasNull),
      _ => false,
    };

void main() {
  late PartoutVpnService engine;
  setUpAll(() => VpnService.instance = engine = PartoutVpnService());

  Future<TaggedModule> importInto(String text) =>
      importWireGuardConfiguration(TaggedModule.empty(ModuleType.wireGuard), text);

  test('import fills an empty module, keeping its id', () async {
    final empty = TaggedModule.empty(ModuleType.wireGuard);
    expect(WireGuardConfiguration(module: empty).hasConfiguration, isFalse);
    final module = await importWireGuardConfiguration(empty, fullConf);
    expect(module.id, empty.id);
    final configuration = WireGuardConfiguration(module: module);
    expect(configuration.hasConfiguration, isTrue);
    expect(configuration.privateKey, '4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=');
    expect(configuration.addressesText, '10.8.0.6/24,fd00::1/64');
    expect(configuration.mtuText, '1420');
    expect(configuration.dnsServersText, '1.1.1.1');
    expect(configuration.dnsDomainsText, 'example.com');
    final peer = configuration.peers.single;
    expect(peer.publicKey, 'muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=');
    expect(peer.preSharedKey, '4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=');
    expect(peer.endpoint, '[1:2:3::4]:12345');
    expect(peer.allowedIPsText, '0.0.0.0/0,::/0');
    expect(peer.keepAliveText, '25');
  });

  test('repeated list keys and hostname endpoints import', () async {
    final repeated = WireGuardConfiguration(module: await importInto(repeatedKeysConf));
    expect(repeated.addresses, <String>['10.8.0.6/24', 'fd00::1/64']);
    expect(repeated.peers.single.allowedIPs, <String>['0.0.0.0/0', '::/0']);
    final hostname = WireGuardConfiguration(module: await importInto(hostnameConf));
    expect(hostname.peers.single.endpoint, 'wg.example.com:51820');
    expect(hostname.peers.single.keepAliveText, '');
  });

  test('a non-WireGuard file is refused', () async {
    await expectLater(importInto('client\nremote 1.2.3.4 1194\n'), throwsA(anything));
  });

  test('editing a peer round-trips through the engine without losing fields', () async {
    final original = await importInto(fullConf);
    final before = keyPaths(original.json);
    var configuration = WireGuardConfiguration(module: original);
    final edited = configuration.withPeer(
      0,
      configuration.peers[0].withEndpoint('vpn.example.org:443').withKeepAlive('30').withAllowedIPs('10.0.0.0/8, 192.168.0.0/16'),
    );
    expect(keyPaths(edited.json), before, reason: 'no field added or lost');
    expect(hasNull(edited.json), isFalse);
    configuration = WireGuardConfiguration(module: edited);
    // listenPort is not shown by the editor and must survive.
    expect(edited.value['configuration']['interface']['listenPort'], 51820);
    expect(configuration.peers[0].endpoint, 'vpn.example.org:443');

    // Through JSON text and the engine's own export/import.
    final reencoded = TaggedModule(json: jsonDecode(jsonEncode(edited.json)) as Map<String, dynamic>);
    expect(reencoded.json, edited.json);
    final exported = await engine.exportModule(edited);
    expect(exported, contains('Endpoint = vpn.example.org:443'));
    expect(exported, contains('PersistentKeepalive = 30'));
    expect(exported, contains('ListenPort = 51820'));
    final reimported = await engine.importModule(exported, contextJson: wireGuardImportContext);
    // The engine gives a re-imported DNS module a new id; everything else matches.
    Map<String, dynamic> withoutDnsId(TaggedModule module) {
      final configuration = jsonDecode(jsonEncode(module.value['configuration'])) as Map<String, dynamic>;
      (configuration['interface']['dns'] as Map).remove('id');
      return configuration;
    }
    expect(withoutDnsId(reimported), withoutDnsId(edited));
    expect(WireGuardConfiguration(module: reimported).peers[0].allowedIPs, <String>['10.0.0.0/8', '192.168.0.0/16']);
  });

  test('clearing optional values removes keys instead of writing nulls', () async {
    final original = await importInto(fullConf);
    var configuration = WireGuardConfiguration(module: original);
    final peer = configuration.peers[0].withPreSharedKey(' ').withEndpoint('').withKeepAlive('');
    var module = configuration.withPeer(0, peer);
    module = WireGuardConfiguration(module: module).withMtu('not a number');
    module = WireGuardConfiguration(module: module).withDnsServers('');
    expect(hasNull(module.json), isFalse);
    final value = module.value['configuration'] as Map;
    expect((value['peers'] as List).single, <String, dynamic>{
      'publicKey': 'muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=',
      'allowedIPs': <String>['0.0.0.0/0', '::/0'],
    });
    expect((value['interface'] as Map).containsKey('mtu'), isFalse);
    expect((value['interface'] as Map).containsKey('dns'), isFalse);
    // A blank private key is ignored, as upstream does.
    expect(WireGuardConfiguration(module: module).withPrivateKey('  ').json, module.json);
  });

  test('DNS edits keep the DNS module id and protocol', () async {
    final original = await importInto(fullConf);
    final dnsBefore = Map<String, dynamic>.from(original.value['configuration']['interface']['dns'] as Map);
    final module = WireGuardConfiguration(module: original).withDnsServers('9.9.9.9, 8.8.8.8');
    final next = WireGuardConfiguration(module: WireGuardConfiguration(module: module).withDnsDomains('a.com,b.com'));
    final dns = next.module.value['configuration']['interface']['dns'] as Map;
    expect(dns['id'], dnsBefore['id']);
    expect(dns['protocolType'], dnsBefore['protocolType']);
    expect(next.dnsServers, <String>['9.9.9.9', '8.8.8.8']);
    expect(next.dnsDomains, <String>['a.com', 'b.com']);
  });

  test('add and remove peers; one empty peer at a time', () async {
    final original = await importInto(hostnameConf);
    final configuration = WireGuardConfiguration(module: original);
    expect(configuration.canAddPeer, isTrue);
    final added = WireGuardConfiguration(module: configuration.addingPeer());
    expect(added.peers, hasLength(2));
    expect(added.peers[1].json, <String, dynamic>{'publicKey': '', 'allowedIPs': <dynamic>[]});
    expect(added.canAddPeer, isFalse);
    expect(added.addingPeer().json, added.module.json);
    final removed = WireGuardConfiguration(module: added.removingPeer(0));
    expect(removed.peers.single.publicKey, '');
  });

  test('IPv6 endpoints stored unbracketed show in wg-quick form', () {
    expect(const WireGuardPeer(json: <String, dynamic>{'endpoint': '1:2:3::4:12345'}).endpoint, '[1:2:3::4]:12345');
    expect(const WireGuardPeer(json: <String, dynamic>{'endpoint': '1.2.3.4:5'}).endpoint, '1.2.3.4:5');
  });

  test('key generation gives a base64 32-byte key and a derivable public key', () async {
    final privateKey = await engine.generateWireGuardKey();
    expect(base64.decode(privateKey), hasLength(32));
    final publicKey = await engine.wireGuardPublicKey(privateKey);
    expect(base64.decode(publicKey), hasLength(32));
    expect(publicKey, isNot(privateKey));
    expect(await engine.wireGuardPublicKey(privateKey), publicKey);
    // Expected value computed independently with Python's X25519.
    expect(await engine.wireGuardPublicKey('4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw='),
        'V2n3Yb4kE+1X0l7bR6vLBddbdrRUvi7WUOB9LJndCWk=');
    await expectLater(engine.wireGuardPublicKey('nope'), throwsA(anything));
  });
}
