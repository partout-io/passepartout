// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/platform/vpn_service_native.dart';

void main() {
  final engine = PartoutVpnService();

  group('Partout OpenVPN Engine Imports', () {
    test('imports sample.ovpn through native Partout ABI', () async {
      final text = File('test/fixtures/sample.ovpn').readAsStringSync();
      final module = await engine.importModule(text);

      expect(module.type, 'OpenVPN');
      final config = module.value['configuration'] as Map<String, dynamic>;
      expect(config['authUserPass'], true);
      expect(config['remotes'], contains('vpn.example.com:UDP:1194'));
      expect(config['ca'], contains('BEGIN CERTIFICATE'));

      // Test export and re-import
      final exported = await engine.exportModule(module);
      expect(exported, contains('remote vpn.example.com 1194'));
      final reimported = await engine.importModule(exported);
      expect(reimported.type, 'OpenVPN');
    });

    test('imports protonvpn.ovpn fixture with TLS wrap and XOR scramble', () async {
      final path = '/home/sigmadev/passepartout/partout/tests/openvpn/fixtures/protonvpn.ovpn';
      if (!File(path).existsSync()) return;

      final text = File(path).readAsStringSync();
      final module = await engine.importModule(text);

      expect(module.type, 'OpenVPN');
      final config = module.value['configuration'] as Map<String, dynamic>;
      expect(config['cipher'], 'AES-256-CBC');
      expect(config['digest'], 'SHA512');
      expect(config['remotes'] as List, hasLength(5));
      expect(config['checksEKU'], true);
      expect(config['randomizeEndpoint'], true);
      expect(config['mtu'], 1500);

      // TLS wrap
      final tlsWrap = config['tlsWrap'] as Map<String, dynamic>;
      expect(tlsWrap['strategy'], 'auth');
      expect((tlsWrap['key'] as Map)['dir'], 1);

      // XOR method
      final xorMethod = config['xorMethod'] as Map<String, dynamic>;
      expect(xorMethod['type'], 'obfuscate');
      expect(xorMethod['mask'], isNotEmpty);
    });

    test('imports pia-hungary.ovpn fixture with multiple remotes and compression', () async {
      final path = '/home/sigmadev/passepartout/partout/tests/openvpn/fixtures/pia-hungary.ovpn';
      if (!File(path).existsSync()) return;

      final text = File(path).readAsStringSync();
      final module = await engine.importModule(text);

      expect(module.type, 'OpenVPN');
      final config = module.value['configuration'] as Map<String, dynamic>;
      expect(config['cipher'], 'AES-128-CBC');
      expect(config['digest'], 'SHA1');
      expect(config['remotes'] as List, hasLength(2));
      expect(config['checksEKU'], true);
    });

    test('JSON round-trip preserves custom and unknown fields', () async {
      final text = File('test/fixtures/sample.ovpn').readAsStringSync();
      final module = await engine.importModule(text);

      // Add a custom/unknown field to configuration and module root
      final customValue = Map<String, dynamic>.from(module.value);
      final customConfig = Map<String, dynamic>.from(customValue['configuration'] as Map);
      customConfig['unknownEngineFeature_2026'] = <String, dynamic>{'enabled': true, 'score': 42};
      customValue['unknownModuleMetadata'] = 'test-meta';
      customValue['configuration'] = customConfig;

      final customModule = module.withValue(customValue);
      final profile = TunnelProfile.empty('OpenVPN Test Profile').savingModule(customModule);

      final encodedJson = profile.encode();
      final decodedProfile = TunnelProfile.decode(encodedJson);
      final decodedModule = decodedProfile.module(customModule.id)!;

      final decodedConfig = decodedModule.value['configuration'] as Map;
      expect(decodedConfig['unknownEngineFeature_2026']['score'], 42);
      expect(decodedModule.value['unknownModuleMetadata'], 'test-meta');
      expect(decodedConfig['remotes'], contains('vpn.example.com:UDP:1194'));
    });
  });
}
