// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// A small validator for the module schemas of Partout's openapi.yaml, and the
// pure-logic tests of the module builders (addresses, subnets, routes).
// The widget tests in modules_editors_test.dart import [validateModule].

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/ui/modules/common/addresses.dart';
import 'package:passepartout/ui/modules/dns_view.dart';
import 'package:passepartout/ui/modules/http_proxy_view.dart';
import 'package:passepartout/ui/modules/ip_view.dart';
import 'package:passepartout/ui/modules/on_demand_view.dart';
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart';

File? _openApiFile() {
  final home = Platform.environment['HOME'] ?? '';
  for (final path in <String>[
    '../partout/scripts/openapi.yaml',
    '$home/passepartout/partout/scripts/openapi.yaml',
  ]) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

Map<String, dynamic>? _schemas;

Map<String, dynamic> get schemas => _schemas ??= () {
      final file = _openApiFile();
      if (file == null) throw StateError('openapi.yaml not found');
      final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
      return Map<String, dynamic>.from((yaml['components'] as YamlMap)['schemas'] as YamlMap);
    }();

/// Errors of [value] against schema [name] (empty when valid).
List<String> validateAgainst(String name, Object? value) {
  final errors = <String>[];
  _validate(schemas[name] as YamlMap, value, name, errors);
  return errors;
}

/// Validates the `value` of a TaggedModule against `<type>Module`.
List<String> validateModule(TaggedModule module) {
  final name = switch (module.type) {
    ModuleType.dns => 'DNSModule',
    ModuleType.httpProxy => 'HTTPProxyModule',
    ModuleType.ip => 'IPModule',
    ModuleType.onDemand => 'OnDemandModule',
    _ => throw ArgumentError(module.type),
  };
  return validateAgainst(name, module.value);
}

YamlMap _resolve(YamlMap schema) {
  final ref = schema[r'$ref'] as String?;
  if (ref == null) return schema;
  return _resolve(schemas[ref.split('/').last] as YamlMap);
}

void _validate(YamlMap rawSchema, Object? value, String path, List<String> errors) {
  final schema = _resolve(rawSchema);
  if (value == null) {
    errors.add('$path: null');
    return;
  }
  final discriminator = schema['discriminator'] as YamlMap?;
  if (discriminator != null && value is Map) {
    final tag = value[discriminator['propertyName']];
    final target = (discriminator['mapping'] as YamlMap)[tag] as String?;
    if (target == null) {
      errors.add('$path: unknown discriminator $tag');
      return;
    }
    _validateObject(_resolve(YamlMap.wrap(<String, String>{r'$ref': target})), value, path, errors);
    return;
  }
  if (schema.containsKey('const') && value != schema['const']) errors.add('$path: expected ${schema['const']}');
  final enumeration = schema['enum'] as YamlList?;
  if (enumeration != null && !enumeration.contains(value)) errors.add('$path: $value not in $enumeration');
  switch (schema['type']) {
    case 'string':
      if (value is! String) errors.add('$path: not a string');
      if (schema['format'] == 'uri' && value is String && Uri.tryParse(value) == null) errors.add('$path: not a uri');
    case 'integer':
      if (value is! int) errors.add('$path: not an integer');
    case 'boolean':
      if (value is! bool) errors.add('$path: not a boolean');
    case 'array':
      if (value is! List) {
        errors.add('$path: not an array');
        return;
      }
      if (schema['uniqueItems'] == true && value.toSet().length != value.length) errors.add('$path: duplicates');
      for (var i = 0; i < value.length; i++) {
        _validate(schema['items'] as YamlMap, value[i], '$path[$i]', errors);
      }
    case 'object':
      _validateObject(schema, value, path, errors);
  }
}

void _validateObject(YamlMap schema, Object? value, String path, List<String> errors) {
  if (value is! Map) {
    errors.add('$path: not an object');
    return;
  }
  final properties = <String, YamlMap>{};
  final required = <String>{};
  void collect(YamlMap part) {
    final resolved = _resolve(part);
    for (final entry in ((resolved['properties'] as YamlMap?) ?? YamlMap()).entries) {
      properties[entry.key as String] = entry.value as YamlMap;
    }
    required.addAll(((resolved['required'] as YamlList?) ?? YamlList()).cast<String>());
  }

  collect(schema);
  for (final part in (schema['allOf'] as YamlList?) ?? YamlList()) {
    final resolved = _resolve(part as YamlMap);
    // allOf of the discriminated base: take its properties, not its discriminator.
    for (final entry in ((resolved['properties'] as YamlMap?) ?? YamlMap()).entries) {
      properties.putIfAbsent(entry.key as String, () => entry.value as YamlMap);
    }
  }
  for (final key in required) {
    if (!value.containsKey(key)) errors.add('$path: missing $key');
  }
  final additional = schema['additionalProperties'];
  for (final entry in value.entries) {
    final key = '${entry.key}';
    final property = properties[key];
    if (property != null) {
      _validate(property, entry.value, '$path.$key', errors);
    } else if (additional is YamlMap) {
      _validate(additional, entry.value, '$path.$key', errors);
    } else if (additional == false) {
      errors.add('$path: unexpected $key');
    }
  }
}

void main() {
  final hasSchema = _openApiFile() != null;

  group('addresses', () {
    test('IPv4 and IPv6', () {
      expect(isIPv4('10.0.0.1'), isTrue);
      expect(isIPv4('256.0.0.1'), isFalse);
      expect(isIPv4('1.2.3'), isFalse);
      expect(isIPv6('::1'), isTrue);
      expect(isIPv6('fe80::1032:2a6b:fec:f49e'), isTrue);
      expect(isIPv6('::ffff:1.2.3.4'), isTrue);
      expect(isIPv6('1:2:3:4:5:6:7:8'), isTrue);
      expect(isIPv6('1:2:3:4:5:6:7:8:9'), isFalse);
      expect(isIPv6('1::2::3'), isFalse);
      expect(isIPv6('fe80::1%en0'), isTrue);
      expect(isIPv6('example.com'), isFalse);
      expect(ParsedAddress.parse(' 1.1.1.1 ')!.rawValue, '1.1.1.1');
      expect(ParsedAddress.parse('host.com')!.isIPAddress, isFalse);
      expect(ParsedAddress.parse('   '), isNull);
    });

    test('subnets normalise like Subnet(rawValue:)', () {
      expect(ParsedSubnet.parse('10.20.30.40/16')!.rawValue, '10.20.30.40/16');
      expect(ParsedSubnet.parse('10.0.0.1')!.rawValue, '10.0.0.1/32');
      expect(ParsedSubnet.parse('fe80::1')!.rawValue, 'fe80::1/128');
      expect(ParsedSubnet.parse('10.0.0.1/33'), isNull);
      expect(ParsedSubnet.parse('10.0.0.1/x'), isNull);
      expect(ParsedSubnet.parse('fe80::1%en0/64'), isNull);
      expect(ParsedSubnet.parse('host.com/24'), isNull);
    });

    test('route descriptions', () {
      expect(routeDescription(<String, dynamic>{}), 'default → *');
      expect(routeDescription(<String, dynamic>{'gateway': '1.2.3.4'}), 'default → 1.2.3.4');
      expect(routeDescription(<String, dynamic>{'destination': '5.5.0.0/16', 'gateway': '5.5.5.5'}), '5.5.0.0/16 → 5.5.5.5');
      expect(routeDescription(<String, dynamic>{'destination': '5.5.0.0/16'}), '5.5.0.0/16');
    });

    test('RouteView.parseAndSubmit rules', () {
      expect(parseRoute(.v4, isDefault: true, destination: 'x', gateway: 'y'), <String, dynamic>{});
      expect(parseRoute(.v4, isDefault: false, destination: '5.5.0.0/16', gateway: '5.5.5.5'),
          <String, dynamic>{'destination': '5.5.0.0/16', 'gateway': '5.5.5.5'});
      expect(parseRoute(.v4, isDefault: false, destination: '5.5.0.0/16', gateway: ''),
          <String, dynamic>{'destination': '5.5.0.0/16'});
      expect(parseRoute(.v4, isDefault: false, destination: 'fe80::/64', gateway: ''), isNull);
      expect(parseRoute(.v4, isDefault: false, destination: '5.5.0.0/16', gateway: 'fe80::1'), isNull);
      expect(parseRoute(.v4, isDefault: false, destination: '5.5.0.0/16', gateway: 'host.com'), isNull);
      expect(parseRoute(.v6, isDefault: false, destination: 'fe80::/64', gateway: 'fe80::1'),
          <String, dynamic>{'destination': 'fe80::/64', 'gateway': 'fe80::1'});
    });
  });

  group('builders round-trip upstream JSON', () {
    test('DNS builder() reads domainName and searchDomains like upstream', () {
      final builder = DnsBuilder.fromJson(<String, dynamic>{
        'id': 'X',
        'protocolType': <String, dynamic>{'type': 'https', 'url': 'https://doh.com/query'},
        'servers': <dynamic>['1.1.1.1'],
        'domainName': 'one.com',
        'searchDomains': <dynamic>['two.net'],
      });
      expect(builder.protocolType, 'https');
      expect(builder.dohURL, 'https://doh.com/query');
      expect(builder.isFirstDomainPrimary, isTrue);
      expect(builder.domains!.map((item) => item.value), <String>['one.com', 'two.net']);
      expect(builder.changes['domainName'], 'one.com');
      expect(builder.changes['searchDomains'], <String>['one.com', 'two.net']);
      expect(builder.validationError, isNull);
    });

    test('DNS legacy protocol encoding is read', () {
      final builder = DnsBuilder.fromJson(<String, dynamic>{
        'id': 'X',
        'protocolType': <String, dynamic>{'tls': <String, dynamic>{'hostname': 'dot.com'}},
        'servers': <dynamic>[],
      });
      expect(builder.protocolType, 'tls');
      expect(builder.dotHostname, 'dot.com');
    });

    test('HTTP proxy endpoints split at the last colon', () {
      final builder = HttpProxyBuilder.fromJson(<String, dynamic>{
        'id': 'X',
        'proxy': '10.10.10.10:1080',
        'secureProxy': 'fe80::1:8080',
        'bypassDomains': <dynamic>['a.com'],
      });
      expect(builder.address, '10.10.10.10');
      expect(builder.port, '1080');
      expect(builder.secureAddress, 'fe80::1');
      expect(builder.securePort, '8080');
      expect(builder.changes['proxy'], '10.10.10.10:1080');
      expect(builder.changes['secureProxy'], 'fe80::1:8080');
    });

    test('IP builder loads the first subnet of each family', () {
      final builder = IpBuilder.fromJson(<String, dynamic>{
        'id': 'X',
        'ipv4': <String, dynamic>{
          'subnets': <dynamic>['10.20.30.40/16'],
          'includedRoutes': <dynamic>[],
          'excludedRoutes': <dynamic>[],
        },
        'mtu': 1400,
      });
      expect(builder.subnetText[AddressFamily.v4], '10.20.30.40/16');
      expect(builder.subnetText[AddressFamily.v6], isNull);
      expect(builder.mtu, '1400');
      expect(builder.changes['ipv6'], isNull);
    });

    test('on-demand SSIDs keep order and state', () {
      final builder = OnDemandBuilder.fromJson(<String, dynamic>{
        'id': 'X',
        'policy': 'excluding',
        'withSSIDs': <String, dynamic>{'One': true, 'Two': false},
        'withOtherNetworks': <dynamic>['mobile'],
      });
      expect(builder.withMobileNetwork, isTrue);
      expect(builder.withEthernetNetwork, isFalse);
      expect(builder.withSSIDs, <String, bool>{'One': true, 'Two': false});
    });
  });

  group('schema validator', () {
    test('accepts upstream-shaped modules and rejects bad ones', () {
      expect(validateModule(TaggedModule.empty(ModuleType.dns)), isEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.httpProxy)), isEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.ip)), isEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.onDemand)), isEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.dns).withField('bogus', 1)), isNotEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.dns).withField('protocolType', <String, dynamic>{'type': 'https'})),
          isNotEmpty);
      expect(validateModule(TaggedModule.empty(ModuleType.onDemand).withField('policy', 'sometimes')), isNotEmpty);
      expect(
          validateModule(TaggedModule.empty(ModuleType.ip).withField('ipv4', <String, dynamic>{'subnets': <dynamic>[]})),
          isNotEmpty);
    });
  }, skip: hasSchema ? false : 'openapi.yaml not found');
}
