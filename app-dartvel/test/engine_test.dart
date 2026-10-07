// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Fixtures adapted from Partout tests/abi/importer.zig, copyright Davide De Rosa.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/platform/vpn_service_native.dart';
void main() {
  final engine = PartoutVpnService();
  for (final (extension, type) in [('ovpn', 'OpenVPN'), ('conf', 'WireGuard')]) {
    test('native $type profile and module import/export', () {
      final text = File('test/fixtures/sample.$extension').readAsStringSync();
      final profile = engine.importProfile(text, 'Imported $type');
      expect(profile.name, 'Imported $type');
      expect(profile.modules.map((m) => m.type), contains(type));
      expect(TunnelProfile.decode(profile.encode()).json, profile.json);
      final module = engine.importModule(text);
      expect(module.type, type);
      expect(engine.importModule(engine.exportModule(module)).type, type);
    });
  }
  test('editing DNS preserves tunnel credentials and other fields', () {
    final profile = engine.importProfile(File('test/fixtures/sample.conf').readAsStringSync(), 'Original');
    final wg = profile.modules.firstWhere((m) => m.type == 'WireGuard');
    final changed = profile.replaceModule(const DnsSettings(id: '00000000-0000-4000-8000-000000000001', protocolType: {'type': 'cleartext'}, servers: ['9.9.9.9']).toModule());
    expect(changed.modules.firstWhere((m) => m.type == 'WireGuard').json, wg.json);
    expect(changed.json['activeModulesIds'], contains('00000000-0000-4000-8000-000000000001'));
  });
  test('WireGuard keys use native crypto', () {
    final key = engine.generateWireGuardKey();
    expect(key.length, 44);
    expect(engine.wireGuardPublicKey(key).length, 44);
  });
  test('connect fails explicitly without privileged helper', () async {
    final profile = engine.importProfile(File('test/fixtures/sample.conf').readAsStringSync(), 'Test');
    await expectLater(engine.connect(profile), throwsUnsupportedError);
  });
}
