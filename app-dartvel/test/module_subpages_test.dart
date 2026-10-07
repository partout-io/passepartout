// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Every module sub-page has its own URL, /profiles/<id>/modules/<moduleId>/<section>:
// it renders from that URL through the app's real router (deep link, no page
// under it), edits reach the profile draft, and back returns to the module.
// Run with PARTOUT_LIBRARY and LD_LIBRARY_PATH set.

import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/main.dart';
import 'package:passepartout/platform/vpn_service.dart';
import 'package:passepartout/platform/vpn_service_native.dart';
import 'package:passepartout/state/app_state.dart';
import 'package:passepartout/state/profile_draft.dart';
import 'package:passepartout/ui/kit.dart';
import 'package:passepartout/ui/modules/module_screen.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_credentials_screen.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_remotes_screen.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_configuration.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_import.dart';

import 'support/app_harness.dart';

const String wireGuardConf = '''
[Interface]
PrivateKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
Address = 10.8.0.6/24, fd00::1/64
DNS = 1.1.1.1, example.com

[Peer]
PublicKey = muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE=
PresharedKey = 4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = wg.example.com:51820
''';

void main() {
  late TunnelProfile profile;
  late TaggedModule wireGuard;
  late TaggedModule openVPN;

  setUpAll(() async {
    final engine = PartoutVpnService();
    VpnService.instance = engine;
    wireGuard = await engine.importModule(wireGuardConf, contextJson: wireGuardImportContext);
    openVPN = await engine.importModule(io.File('test/fixtures/sample.ovpn').readAsStringSync());
    profile = TunnelProfile.empty('Office').savingModule(wireGuard).savingModule(openVPN);
  });

  setUp(() {
    setUpApp();
    DV.global<ProfilesState>(ProfilesState(isReady: true, profiles: <TunnelProfile>[profile]));
  });
  tearDown(DVNavigation.detach);

  /// Lets deferred page libraries load (real event loop), then settles.
  Future<void> settle(WidgetTester tester) async {
    for (var round = 0; round < 3; round++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      // Not pumpAndSettle: a loading indicator would spin forever.
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// Starts the real app and opens [target] as a deep link.
  Future<void> openUrl(WidgetTester tester, DVRouteTarget target) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(createDartvelApp());
      await tester.pump();
    });
    await settle(tester);
    DV.Navigation.navigate(target);
    await settle(tester);
  }

  DVRouteTarget section(TaggedModule module, String name) =>
      DVRoutes.profilesmodulesIdModuleIdSection(id: profile.id, moduleId: module.id, section: name);

  final wireGuardPages = <String, (String title, String text)>{
    'private-key': ('Private key', '4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw='),
    'addresses': ('Addresses', '10.8.0.6/24,fd00::1/64'),
    'dns-servers': ('Servers', '1.1.1.1'),
    'dns-domains': ('Search domains', 'example.com'),
    'peer-1-public-key': ('Public key', 'muwialz9E36nXp9qgbGIxwMrH+5Ovr8d7cutH8JHdvE='),
    'peer-1-preshared-key': ('Pre-shared key', '4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw='),
    'peer-1-endpoint': ('Endpoint', 'wg.example.com:51820'),
    'peer-1-allowed-ips': ('Allowed IPs', '0.0.0.0/0,::/0'),
  };

  // One app per test file: Dartvel's generated router sets itself up once per
  // process, so a second app in the same file renders nothing. The steps below
  // share that one app and open each URL in turn, as a deep link.
  testWidgets('every module sub-page renders from its URL; edits reach the draft; back goes to the module', (tester) async {
    // A deep link with nothing under it: a back button to the module page.
    await openUrl(tester, section(wireGuard, 'peer-1-endpoint'));
    expect(find.byType(PSLongContentPage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(DV.Navigation.currentPath, '/profiles/${profile.id}/modules/${wireGuard.id}');
    expect(find.text('PEER #1'), findsOneWidget);

    for (final MapEntry(key: name, value: (title, text)) in wireGuardPages.entries) {
      DV.Navigation.navigate(section(wireGuard, name));
      await settle(tester);
      expect(find.text(title), findsOneWidget, reason: name);
      expect(find.byType(PSLongContentPage), findsOneWidget, reason: name);
      expect(find.widgetWithText(TextField, text), findsOneWidget, reason: name);
      expect(find.byType(BackButton), findsOneWidget, reason: name);
    }

    final config = openVPN.value['configuration'] as Map;
    DV.Navigation.navigate(section(openVPN, 'remotes'));
    await settle(tester);
    expect(find.byType(OpenVPNRemotesScreen), findsOneWidget);
    if (config['authUserPass'] == true) {
      DV.Navigation.navigate(section(openVPN, 'credentials'));
      await settle(tester);
      expect(find.byType(OpenVPNCredentialsScreen), findsOneWidget);
    }
    DV.Navigation.navigate(section(openVPN, 'ca'));
    await settle(tester);
    expect(find.text('CA'), findsOneWidget);
    expect(find.text(config['ca'] as String), findsOneWidget);
    expect(find.byIcon(Icons.copy), findsOneWidget);
    for (final (name, key) in <(String, String)>[
      ('certificate', 'clientCertificate'),
      ('key', 'clientKey'),
      ('tls-wrap', 'tlsWrap'),
      ('data-ciphers', 'dataCiphers'),
      ('xor', 'xorMethod'),
    ]) {
      if (config[key] == null) continue;
      DV.Navigation.navigate(section(openVPN, name));
      await settle(tester);
      expect(find.byType(PSLongContentPage), findsOneWidget, reason: name);
    }

    // A stale or mistyped section says so.
    DV.Navigation.navigate(section(wireGuard, 'peer-9-endpoint'));
    await settle(tester);
    expect(find.text(tr(Strings.globalNounsNoContent)), findsOneWidget);

    // From the module page: tap a row, the sub-page opens at its URL, an edit
    // reaches the draft, and back pops to the module page showing the edit.
    DV.Navigation.navigate(DVRoutes.profilesmodules(id: profile.id, moduleId: wireGuard.id));
    await settle(tester);
    await tester.tap(find.widgetWithText(PSLongContentRow, 'Endpoint'));
    await settle(tester);
    expect(find.byType(PSLongContentPage), findsOneWidget);
    // Pushed as the route /profiles/<id>/modules/<moduleId>/peer-1-endpoint.
    // (go_router keeps the browser URL at the page underneath after a push;
    // see docs/DARTVEL-GAPS.md.)
    expect(tester.widget<ModuleSectionScreen>(find.byType(ModuleSectionScreen)).section, 'peer-1-endpoint');
    expect(find.byType(BackButton), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'vpn.example.org:443');
    await tester.pump();
    final draftModule = DraftStore.state.profile!.module(wireGuard.id)!;
    expect(WireGuardConfiguration(module: draftModule).peers.single.endpoint, 'vpn.example.org:443');
    expect(DraftStore.state.isDirty, isTrue);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(PSLongContentPage), findsNothing);
    expect(find.text('PEER #1'), findsOneWidget);
    expect(find.text('vpn.example.org:443'), findsOneWidget); // the row shows the edit
  });
}
