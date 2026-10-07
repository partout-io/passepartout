// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Unit tests of lib/domain/profile.dart: lossless JSON, module editing in
// upstream ProfileEditor's semantics, validation order, and the defaults of
// every addable module against openapi.yaml. Real profiles come from the
// Partout engine importing test/fixtures/sample.{ovpn,conf}.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/platform/vpn_service_native.dart';

import 'modules_schema_test.dart' show validateAgainst;

bool get _hasEngine {
  final path = Platform.environment['PARTOUT_LIBRARY'];
  return path != null && File(path).existsSync();
}

bool get _hasSchema =>
    File('${Platform.environment['HOME']}/passepartout/partout/scripts/openapi.yaml').existsSync() ||
    File('../partout/scripts/openapi.yaml').existsSync();

TaggedModule _module(String type, String id, [Map<String, dynamic> extra = const <String, dynamic>{}]) =>
    TaggedModule.of(type, <String, dynamic>{'id': id, ...extra});

/// A profile with OpenVPN (active), WireGuard, DNS (active) and IP, plus unknown fields.
TunnelProfile _sample() => TunnelProfile(json: <String, dynamic>{
      'version': 1,
      'id': 'P',
      'name': 'Sample',
      'userInfo': <String, dynamic>{'note': 'kept'},
      'modules': <dynamic>[
        _module(ModuleType.openVPN, 'O', <String, dynamic>{'configuration': <String, dynamic>{'remotes': <dynamic>[]}}).json,
        _module(ModuleType.wireGuard, 'W', <String, dynamic>{'configuration': <String, dynamic>{}}).json,
        TaggedModule.of(ModuleType.dns, <String, dynamic>{
          'id': 'D',
          'protocolType': <String, dynamic>{'type': 'cleartext'},
          'servers': <dynamic>['1.1.1.1'],
        }).json,
        _module(ModuleType.ip, 'I').json,
      ],
      'activeModulesIds': <dynamic>['O', 'D'],
    });

void main() {
  group('JSON', () {
    test('decode/encode round trip keeps unknown fields', () {
      final text = jsonEncode(<String, dynamic>{
        ..._sample().json,
        'futureTopLevel': <String, dynamic>{'a': 1},
      });
      final profile = TunnelProfile.decode(text);
      expect(jsonDecode(profile.encode()), jsonDecode(text));
      expect(profile.json['futureTopLevel'], <String, dynamic>{'a': 1});
      expect(profile.renamed('X').json['userInfo'], <String, dynamic>{'note': 'kept'});
    });

    test('decode rejects JSON that is not a profile', () {
      expect(() => TunnelProfile.decode('{"id":"x"}'), throwsFormatException);
      expect(() => TunnelProfile.decode('{"id":1,"name":"a","modules":[],"activeModulesIds":[]}'), throwsFormatException);
    });

    test('empty profile', () {
      final profile = TunnelProfile.empty('New');
      expect(profile.name, 'New');
      expect(profile.modules, isEmpty);
      expect(profile.activeModuleIds, isEmpty);
      expect(profile.id, matches(RegExp(r'^[0-9A-F-]{36}$')));
      expect(TunnelProfile.empty('New').id, isNot(profile.id));
      if (_hasSchema) expect(validateAgainst('Profile', profile.json), isEmpty);
    });

    test('renamed and withBehavior', () {
      final profile = _sample();
      expect(profile.renamed('Other').name, 'Other');
      expect(profile.name, 'Sample', reason: 'immutable');
      expect(profile.disconnectsOnSleep, isFalse);
      final sleeping = profile.withBehavior(disconnectsOnSleep: true);
      expect(sleeping.disconnectsOnSleep, isTrue);
      expect(sleeping.includesAllNetworks, isFalse);
      expect((sleeping.json['behavior'] as Map).containsKey('includesAllNetworks'), isFalse);
      final both = sleeping.withBehavior(includesAllNetworks: true);
      expect(both.disconnectsOnSleep, isTrue, reason: 'keeps the other flag');
      expect(both.includesAllNetworks, isTrue);
      expect(both.withBehavior(disconnectsOnSleep: false).includesAllNetworks, isTrue);
    });
  });

  group('modules', () {
    test('savingModule adds as active and replaces in place', () {
      final profile = _sample();
      final dns2 = TaggedModule.empty(ModuleType.dns);
      final added = profile.savingModule(dns2);
      expect(added.modules.last.id, dns2.id);
      expect(added.isActive(dns2.id), isTrue);

      final edited = added.savingModule(_module(ModuleType.ip, 'I', <String, dynamic>{'mtu': 1400}));
      expect(edited.modules.map((m) => m.id), added.modules.map((m) => m.id), reason: 'same position');
      expect(edited.module('I')!.value['mtu'], 1400);
      expect(edited.isActive('I'), isFalse, reason: 'replacing does not activate');
      expect(edited.savingModule(edited.module('I')!, activate: true).isActive('I'), isTrue);
      expect(edited.savingModule(TaggedModule.empty(ModuleType.ip), activate: false).activeModuleIds,
          edited.activeModuleIds);
    });

    test('activating a connection keeps the other connection active (upstream ProfileEditor)', () {
      final profile = _sample();
      final toggled = profile.togglingModule('W');
      expect(toggled.isActive('W'), isTrue);
      expect(toggled.isActive('O'), isTrue);
      final saved = profile.savingModule(_module(ModuleType.wireGuard, 'W2'));
      expect(saved.isActive('W2'), isTrue);
      expect(saved.isActive('O'), isTrue);
      expect(toggled.validate()!.kind, ProfileProblemKind.incompatibleModules);
    });

    test('togglingModule flips one module', () {
      final profile = _sample();
      expect(profile.togglingModule('D').isActive('D'), isFalse);
      expect(profile.togglingModule('I').isActive('I'), isTrue);
      expect(profile.togglingModule('I').togglingModule('I').activeModuleIds, profile.activeModuleIds);
    });

    test('activeModulesIds follows module order', () {
      final profile = _sample().togglingModule('I');
      expect(profile.json['activeModulesIds'], <String>['O', 'D', 'I']);
    });

    test('removingModule drops the module and its active id', () {
      final profile = _sample().removingModule('O');
      expect(profile.module('O'), isNull);
      expect(profile.activeModuleIds, <String>{'D'});
      expect(profile.json['activeModulesIds'], <String>['D']);
    });

    test('movingModule uses list-move semantics', () {
      final profile = _sample();
      expect(profile.movingModule(0, 4).modules.map((m) => m.id), <String>['W', 'D', 'I', 'O']);
      expect(profile.movingModule(3, 0).modules.map((m) => m.id), <String>['I', 'O', 'W', 'D']);
      expect(profile.movingModule(1, 1).modules.map((m) => m.id), <String>['O', 'W', 'D', 'I']);
      expect(profile.movingModule(0, 4).activeModuleIds, profile.activeModuleIds);
    });

    test('duplicated gets fresh ids and remaps active ids', () {
      final profile = _sample();
      final copy = profile.duplicated('Sample 2');
      expect(copy.id, isNot(profile.id));
      expect(copy.name, 'Sample 2');
      expect(copy.modules.length, profile.modules.length);
      final oldIds = profile.modules.map((m) => m.id).toSet();
      expect(copy.modules.map((m) => m.id).toSet().intersection(oldIds), isEmpty);
      expect(copy.modules.map((m) => m.type), profile.modules.map((m) => m.type));
      // Active modules are the same by position.
      final activePositions = <int>[for (var i = 0; i < profile.modules.length; i++) if (profile.isActive(profile.modules[i].id)) i];
      final copyPositions = <int>[for (var i = 0; i < copy.modules.length; i++) if (copy.isActive(copy.modules[i].id)) i];
      expect(copyPositions, activePositions);
      expect(copy.json['userInfo'], profile.json['userInfo']);
      expect(copy.modules.first.value['configuration'], profile.modules.first.value['configuration']);
    });

    test('moduleSummary lists active modules in order; activeConnection', () {
      final profile = _sample();
      expect(profile.moduleSummary, 'OpenVPN, DNS');
      expect(profile.activeConnection!.id, 'O');
      final more = profile.savingModule(TaggedModule.empty(ModuleType.httpProxy)).savingModule(TaggedModule.empty(ModuleType.onDemand));
      expect(more.moduleSummary, 'OpenVPN, DNS, HTTP Proxy, On-demand');
      expect(profile.togglingModule('O').activeConnection, isNull);
    });

    test('withField(null) removes the key, never writes null', () {
      final module = _module(ModuleType.ip, 'I', <String, dynamic>{'mtu': 1400});
      final cleared = module.withField('mtu', null);
      expect(cleared.value.containsKey('mtu'), isFalse);
      expect(module.value['mtu'], 1400, reason: 'immutable');
      expect(module.withField('mtu', 1500).value['mtu'], 1500);
      expect(module.withId('X').id, 'X');
      expect(module.withField('absent', null).value, module.value);
    });

    test('TaggedModule.empty matches openapi.yaml for every addable type', () {
      const schemaNames = <String, String>{
        ModuleType.dns: 'DNSModule',
        ModuleType.httpProxy: 'HTTPProxyModule',
        ModuleType.ip: 'IPModule',
        ModuleType.onDemand: 'OnDemandModule',
        ModuleType.openVPN: 'OpenVPNModule',
        ModuleType.wireGuard: 'WireGuardModule',
      };
      for (final type in ModuleType.addable) {
        final module = TaggedModule.empty(type);
        expect(module.type, type);
        expect(module.id, isNotEmpty);
        expect(validateAgainst(schemaNames[type]!, module.value), isEmpty, reason: type);
        expect(validateAgainst('TaggedModule', module.json), isEmpty, reason: type);
      }
    }, skip: _hasSchema ? false : 'openapi.yaml not found');
  });

  group('validate (upstream ProfileEditor order)', () {
    test('valid sample', () => expect(_sample().validate(), isNull));

    test('empty name comes first', () {
      final problem = _sample().renamed('  ').togglingModule('O').togglingModule('D').validate();
      expect(problem!.kind, ProfileProblemKind.emptyName);
    });

    test('no active modules', () {
      expect(_sample().togglingModule('O').togglingModule('D').validate()!.kind, ProfileProblemKind.noActiveModules);
    });

    test('incompatible modules carry the connection ids', () {
      final problem = _sample().togglingModule('W').validate()!;
      expect(problem.kind, ProfileProblemKind.incompatibleModules);
      expect(problem.moduleIds, <String>{'O', 'W'});
    });

    test('incomplete connection module', () {
      final profile = _sample().togglingModule('O').savingModule(TaggedModule.empty(ModuleType.openVPN));
      final problem = profile.validate()!;
      expect(problem.kind, ProfileProblemKind.incompleteModule);
      expect(problem.moduleType, 'OpenVPN');
      expect(problem.moduleIds, <String>{profile.modules.last.id});
    });

    test('modules without a connection are valid', () {
      expect(_sample().togglingModule('O').validate(), isNull);
    });
  });

  group('engine fixtures', () {
    for (final (extension, type) in <(String, String)>[('ovpn', ModuleType.openVPN), ('conf', ModuleType.wireGuard)]) {
      test('imported $type profile edits losslessly', () async {
        final engine = PartoutVpnService();
        final text = File('test/fixtures/sample.$extension').readAsStringSync();
        final profile = await engine.importProfile(text, 'Imported');
        expect(profile.validate(), isNull);
        expect(profile.activeConnection!.type, type);
        final connection = profile.activeConnection!;
        if (_hasSchema) expect(validateAgainst('Profile', profile.json), isEmpty);

        final edited = profile
            .renamed('Renamed')
            .withBehavior(disconnectsOnSleep: true)
            .savingModule(TaggedModule.empty(ModuleType.dns))
            .movingModule(profile.modules.length, 0);
        expect(edited.module(connection.id)!.json, connection.json, reason: 'credentials untouched');
        expect(TunnelProfile.decode(edited.encode()).json, edited.json);
        expect(edited.modules.first.type, ModuleType.dns);

        final copy = edited.duplicated('Copy');
        expect(copy.activeConnection!.value['configuration'], connection.value['configuration']);
        expect(copy.activeConnection!.id, isNot(connection.id));
        // The engine accepts the edited module back.
        expect((await engine.importModule(await engine.exportModule(copy.activeConnection!))).type, type);
      });
    }
  }, skip: _hasEngine ? false : 'PARTOUT_LIBRARY not set');
}
