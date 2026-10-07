// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Widget tests of the DNS, HTTP proxy, IP and on-demand module editors: each
// renders its sections in a MaterialApp, edits fields like a user, and checks
// the module JSON it writes against openapi.yaml.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/ui/kit.dart';
import 'package:passepartout/ui/modules/common/editable_list_section.dart';
import 'package:passepartout/ui/modules/common/module_validation.dart';
import 'package:passepartout/ui/modules/dns_view.dart';
import 'package:passepartout/ui/modules/http_proxy_view.dart';
import 'package:passepartout/ui/modules/ip_view.dart';
import 'package:passepartout/ui/modules/module_view.dart';
import 'package:passepartout/ui/modules/on_demand_view.dart';

import 'modules_schema_test.dart' show validateModule;

/// Holds a module like the profile draft does and re-renders on every edit.
class _Harness extends StatefulWidget {
  const _Harness({required this.initial, required this.sections, required this.edits});

  final TaggedModule initial;
  final ModuleSections sections;
  final List<TaggedModule> edits;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late TaggedModule _module = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PSForm(
          children: widget.sections(
            context,
            ModuleViewArgs(
              profileId: 'P',
              module: _module,
              onChanged: (module) => setState(() {
                _module = module;
                widget.edits.add(module);
              }),
            ),
          ),
        ),
      );
}

Future<List<TaggedModule>> _pump(WidgetTester tester, TaggedModule module, ModuleSections sections) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final edits = <TaggedModule>[];
  await tester.pumpWidget(MaterialApp(
    theme: passepartoutTheme(Brightness.light),
    home: _Harness(initial: module, sections: sections, edits: edits),
  ));
  return edits;
}

Map<String, dynamic> _last(List<TaggedModule> edits) {
  expect(edits, isNotEmpty);
  expect(validateModule(edits.last), isEmpty, reason: '${edits.last.value}');
  return edits.last.value;
}

/// The TextField inside the PSTextRow keyed [key].
Finder _field(String key) => find.descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(TextField));

Future<void> _pick(WidgetTester tester, String row, String option) async {
  await tester.tap(find.widgetWithText(ListTile, row));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, option));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    const DVI18n().loadAll(stringCatalogs.values);
    const DVI18n().useLocale(const LocaleTag('en'));
  });

  group('DNS', () {
    testWidgets('servers, protocol, domains and policies write DNSModule', (tester) async {
      final module = TaggedModule.empty(ModuleType.dns);
      final edits = await _pump(tester, module, dnsSections);
      expect(find.text('Inherit from VPN'), findsOneWidget);
      expect(find.text('Servers'.toUpperCase()), findsOneWidget);

      await _tapText(tester, 'Add address');
      await tester.enterText(find.byType(ListItemTextField).first, '1.1.1.1');
      await tester.pump();
      expect(_last(edits)['servers'], <String>['1.1.1.1']);
      expect(moduleValidationError(edits.last), isNull);

      // A second, invalid server is held back and reported like upstream.
      await _tapText(tester, 'Add address');
      await tester.enterText(find.byType(ListItemTextField).at(1), 'not-an-ip');
      await tester.pump();
      expect(_last(edits)['servers'], <String>['1.1.1.1']);
      expect(moduleValidationError(edits.last), 'Servers must be IP addresses.');
      expect(find.text('not-an-ip'), findsOneWidget, reason: 'typed text survives the rebuild');
      await tester.tap(find.byIcon(Icons.remove_circle).at(1));
      await tester.pumpAndSettle();
      expect(moduleValidationError(edits.last), isNull);

      // Domains, first is primary.
      await _tapText(tester, 'Add domain');
      await tester.enterText(find.byType(ListItemTextField).at(1), 'example.com');
      await tester.pump();
      await _tapText(tester, 'First is primary');
      var value = _last(edits);
      expect(value['searchDomains'], <String>['example.com']);
      expect(value['domainName'], 'example.com');

      // Split DNS: only for configured domains.
      await _tapText(tester, 'Only for configured domains');
      expect(_last(edits)['domainPolicy'], 'matchAndSearch');
      await _tapText(tester, 'Only for configured domains');
      expect(_last(edits).containsKey('domainPolicy'), isFalse);

      // Route through VPN: Default / Yes / No.
      await _pick(tester, 'Route through VPN', 'Yes');
      expect(_last(edits)['routesThroughVPN'], isTrue);
      await _pick(tester, 'Route through VPN', 'Default');
      expect(_last(edits).containsKey('routesThroughVPN'), isFalse);

      // DoH: protocol switches only once the URL is valid; domains hide.
      await _pick(tester, 'Protocol', 'Over HTTPS');
      expect(find.text('Add domain'), findsNothing);
      expect(_last(edits)['protocolType'], <String, dynamic>{'type': 'cleartext'});
      expect(moduleValidationError(edits.last), 'Invalid DoH URL.');
      await tester.enterText(_field('dns/dohURL'), 'https://doh.example/query');
      await tester.pump();
      value = _last(edits);
      expect(value['protocolType'], <String, dynamic>{'type': 'https', 'url': 'https://doh.example/query'});
      expect(moduleValidationError(edits.last), isNull);

      // DoT.
      await _pick(tester, 'Protocol', 'Over TLS');
      await tester.enterText(_field('dns/dotHostname'), 'dot.example');
      await tester.pump();
      expect(_last(edits)['protocolType'], <String, dynamic>{'type': 'tls', 'hostname': 'dot.example'});
    });

    testWidgets('inherit from VPN hides custom settings and keeps unknown fields', (tester) async {
      final module = TaggedModule.of(ModuleType.dns, <String, dynamic>{
        'id': 'D',
        'protocolType': <String, dynamic>{'type': 'cleartext'},
        'servers': <dynamic>['9.9.9.9'],
        'futureField': 'kept',
      });
      final edits = await _pump(tester, module, dnsSections);
      expect(find.text('9.9.9.9'), findsOneWidget);
      await _tapText(tester, 'Inherit from VPN');
      expect(find.text('Custom settings'.toUpperCase()), findsNothing);
      final value = edits.last.value;
      expect(value['inheritsVPN'], isTrue);
      expect(value['servers'], isEmpty);
      expect(value['futureField'], 'kept');
      expect(value.values.contains(null), isFalse);
      // Turning it off again restores what was typed (the builder holds it).
      await _tapText(tester, 'Inherit from VPN');
      expect(edits.last.value['servers'], <String>['9.9.9.9']);
    });
  });

  group('HTTP proxy', () {
    testWidgets('endpoints, PAC and bypass domains write HTTPProxyModule', (tester) async {
      final edits = await _pump(tester, TaggedModule.empty(ModuleType.httpProxy), httpProxySections);
      expect(find.text('HTTP'), findsOneWidget);
      expect(find.text('HTTPS'), findsOneWidget);
      expect(find.text('PAC'), findsOneWidget);

      await tester.enterText(_field('proxy/http/address'), '10.10.10.10');
      await tester.pump();
      expect(_last(edits).containsKey('proxy'), isFalse, reason: 'no port yet');
      await tester.enterText(_field('proxy/http/port'), '1080');
      await tester.pump();
      expect(_last(edits)['proxy'], '10.10.10.10:1080');

      await tester.enterText(_field('proxy/https/address'), 'proxy.example');
      await tester.enterText(_field('proxy/https/port'), '8080');
      await tester.pump();
      expect(_last(edits).containsKey('secureProxy'), isFalse);
      expect(moduleValidationError(edits.last), 'Invalid HTTPS address.');
      await tester.enterText(_field('proxy/https/address'), '20.20.20.20');
      await tester.pump();
      expect(_last(edits)['secureProxy'], '20.20.20.20:8080');

      await tester.enterText(_field('proxy/pac'), 'http://proxy-pac.url');
      await tester.pump();
      expect(_last(edits)['pacURL'], 'http://proxy-pac.url');

      await _tapText(tester, 'Add bypass domain');
      expect(moduleValidationError(edits.last), 'Invalid bypass domains.', reason: 'empty row, as upstream');
      await tester.enterText(find.byType(ListItemTextField).first, 'bypass.example');
      await tester.pump();
      expect(_last(edits)['bypassDomains'], <String>['bypass.example']);
      expect(moduleValidationError(edits.last), isNull);

      await tester.enterText(_field('proxy/http/port'), '');
      await tester.pump();
      expect(_last(edits).containsKey('proxy'), isFalse);
    });
  });

  group('IP', () {
    testWidgets('addresses, routes and MTU write IPModule', (tester) async {
      final edits = await _pump(tester, TaggedModule.empty(ModuleType.ip), ipSections);
      expect(find.text('IPV4'), findsOneWidget);
      expect(find.text('IPV6'), findsOneWidget);
      expect(find.text('Include route'), findsNWidgets(2));

      await tester.enterText(_field('ip/v4/address'), '10.20.30.40/16');
      await tester.pump();
      expect(_last(edits)['ipv4'], <String, dynamic>{
        'subnets': <String>['10.20.30.40/16'],
        'includedRoutes': <dynamic>[],
        'excludedRoutes': <dynamic>[],
      });
      await tester.enterText(_field('ip/v4/address'), '10.20.30');
      await tester.pump();
      expect(_last(edits).containsKey('ipv4'), isFalse, reason: 'nilIfEmpty');
      await tester.enterText(_field('ip/v4/address'), '10.20.30.40');
      await tester.pump();
      expect((_last(edits)['ipv4'] as Map)['subnets'], <String>['10.20.30.40/32']);

      // Include a route on IPv4: wrong family is ignored, like upstream.
      await tester.tap(find.text('Include route').first);
      await tester.pumpAndSettle();
      expect(find.byType(RouteDialog), findsOneWidget);
      await tester.enterText(_field('route/destination'), 'fe80::/64');
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteDialog), findsOneWidget);
      await tester.enterText(_field('route/destination'), '5.5.0.0/16');
      await tester.enterText(_field('route/gateway'), '5.5.5.5');
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect(find.byType(RouteDialog), findsNothing);
      expect((_last(edits)['ipv4'] as Map)['includedRoutes'], <dynamic>[
        <String, dynamic>{'destination': '5.5.0.0/16', 'gateway': '5.5.5.5'},
      ]);
      expect(find.text('5.5.0.0/16 → 5.5.5.5'), findsOneWidget);

      // Default route excluded on IPv6 creates the settings.
      await tester.tap(find.text('Exclude route').last);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Default');
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      expect((_last(edits)['ipv6'] as Map)['excludedRoutes'], <dynamic>[<String, dynamic>{}]);
      expect(find.text('default → *'), findsOneWidget);

      // Remove the IPv4 route.
      await tester.tap(find.descendant(
          of: find.byKey(const ValueKey<String>('ip/v4/included')), matching: find.byIcon(Icons.remove_circle)));
      await tester.pumpAndSettle();
      expect((_last(edits)['ipv4'] as Map)['includedRoutes'], isEmpty);

      await tester.enterText(_field('ip/mtu'), '1400');
      await tester.pump();
      expect(_last(edits)['mtu'], 1400);
      await tester.enterText(_field('ip/mtu'), '14x');
      await tester.pump();
      expect(_last(edits).containsKey('mtu'), isFalse);
    });
  });

  group('On-demand', () {
    testWidgets('policy, networks and SSIDs write OnDemandModule', (tester) async {
      final edits = await _pump(tester, TaggedModule.empty(ModuleType.onDemand), onDemandSections);
      expect(find.text('Activate the VPN in any network.'), findsOneWidget);
      expect(find.text('Add SSID'), findsNothing);

      await _pick(tester, 'Policy', 'Excluding');
      expect(_last(edits)['policy'], 'excluding');
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Ethernet (Mac/TV)'), findsOneWidget);

      await _tapText(tester, 'Mobile');
      expect(_last(edits)['withOtherNetworks'], <String>['mobile']);
      await _tapText(tester, 'Ethernet (Mac/TV)');
      expect(_last(edits)['withOtherNetworks'], <String>['mobile', 'ethernet']);
      await _tapText(tester, 'Mobile');
      expect(_last(edits)['withOtherNetworks'], <String>['ethernet']);

      await _tapText(tester, 'Add SSID');
      await tester.enterText(find.byType(ListItemTextField).first, 'Home');
      await tester.pump();
      expect(_last(edits)['withSSIDs'], <String, dynamic>{'Home': false});
      await tester.tap(find.byType(Switch).last);
      await tester.pumpAndSettle();
      expect(_last(edits)['withSSIDs'], <String, dynamic>{'Home': true});

      await _tapText(tester, 'Add SSID');
      await tester.enterText(find.byType(ListItemTextField).at(1), 'Office');
      await tester.pump();
      expect(_last(edits)['withSSIDs'], <String, dynamic>{'Home': true, 'Office': false});
      await tester.tap(find.byIcon(Icons.remove_circle).first);
      await tester.pumpAndSettle();
      expect(_last(edits)['withSSIDs'], <String, dynamic>{'Office': false});

      await _pick(tester, 'Policy', 'All networks');
      expect(find.text('Add SSID'), findsNothing);
      expect(_last(edits)['policy'], 'any');
    });
  });
}
