// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Renders the WireGuard sections against the real Partout engine and edits
// through the UI. Run with PARTOUT_LIBRARY and LD_LIBRARY_PATH set.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/platform/vpn_service.dart';
import 'package:passepartout/platform/vpn_service_native.dart';
import 'package:passepartout/ui/kit.dart';
import 'package:passepartout/ui/modules/module_view.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_configuration.dart';
import 'package:passepartout/ui/modules/wireguard/wireguard_import.dart';
import 'package:passepartout/ui/modules/wireguard_view.dart';

const String conf = '''
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

/// Hosts the sections the way ModuleScreen does, holding the draft module.
class _Host extends StatefulWidget {
  const _Host({required this.initial, required this.onModule});

  final TaggedModule initial;
  final ValueChanged<TaggedModule> onModule;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late TaggedModule module = widget.initial;

  @override
  Widget build(BuildContext context) => PSScaffold(
        title: 'WireGuard',
        body: Builder(
          builder: (context) => PSForm(
            children: wireGuardSections(
              context,
              ModuleViewArgs(
                profileId: 'profile',
                module: module,
                onChanged: (next) {
                  setState(() => module = next);
                  widget.onModule(next);
                },
              ),
            ),
          ),
        ),
      );
}

void main() {
  late PartoutVpnService engine;
  setUpAll(() {
    VpnService.instance = engine = PartoutVpnService();
    const DVI18n().loadAll(stringCatalogs.values);
    const DVI18n().useLocale(const LocaleTag('en'));
  });

  Future<TaggedModule> pumpHost(WidgetTester tester, TaggedModule initial) async {
    var latest = initial;
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: _Host(initial: initial, onModule: (next) => latest = next)));
    await tester.pumpAndSettle();
    // Callers read the latest module through the returned getter below.
    _latest = () => latest;
    return latest;
  }

  testWidgets('a module without configuration offers only the import', (tester) async {
    await pumpHost(tester, TaggedModule.empty(ModuleType.wireGuard));
    expect(find.text(tr(Strings.modulesGeneralRowsImportFromFile)), findsOneWidget);
    expect(find.text(tr(Strings.modulesWireguardInterface).toUpperCase()), findsNothing);
    expect(find.text(tr(Strings.modulesWireguardPeerAdd)), findsNothing);
  });

  testWidgets('import from file fills the configuration', (tester) async {
    wireGuardFileReader = () async => conf;
    final empty = TaggedModule.empty(ModuleType.wireGuard);
    await pumpHost(tester, empty);
    await tester.tap(find.text(tr(Strings.modulesGeneralRowsImportFromFile)));
    await tester.pumpAndSettle();
    final module = _latest();
    expect(module.id, empty.id);
    expect(WireGuardConfiguration(module: module).peers, hasLength(1));
    expect(find.text(tr(Strings.modulesWireguardPeer, <Object>[1]).toUpperCase()), findsOneWidget);
    expect(find.text(tr(Strings.modulesWireguardPeerAdd)), findsOneWidget);
  });

  testWidgets('sections, edit a peer, add and delete peers, without losing fields', (tester) async {
    final original = await engine.importModule(conf, contextJson: wireGuardImportContext);
    await pumpHost(tester, original);

    // Section order and headers, as upstream.
    final headers = <String>[
      tr(Strings.modulesWireguardInterface).toUpperCase(),
      'DNS',
      tr(Strings.modulesWireguardPeer, <Object>[1]).toUpperCase(),
    ];
    expect(find.text('PEER #1'), findsOneWidget); // real English strings, not keys
    final positions = headers.map((header) => tester.getTopLeft(find.text(header)).dy).toList();
    expect(positions, orderedEquals(<double>[...positions]..sort()));
    expect(find.text(tr(Strings.modulesWireguardInterfaceDnsFooter)), findsOneWidget);
    expect(find.text('MTU'), findsOneWidget);
    expect(find.text(tr(Strings.globalNounsEntriesN, <Object>[2])), findsNWidgets(2)); // addresses, allowed IPs
    expect(find.text(tr(Strings.globalNounsEntriesOne)), findsNWidgets(2)); // DNS servers, domains

    // Derived public key (independently computed with X25519).
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(find.text('V2n3Yb4kE+1X0l7bR6vLBddbdrRUvi7WUOB9LJndCWk='), findsOneWidget);

    // Keep-alive: an inline text field.
    final keepAlive = find.descendant(
      of: find.widgetWithText(PSTextRow, tr(Strings.globalNounsKeepAlive)),
      matching: find.byType(TextField),
    );
    await tester.enterText(keepAlive, '60');
    await tester.pump();

    // Endpoint: its row shows the value; its own page (a route, tested from
    // its URL in module_subpages_test.dart) edits it.
    expect(find.widgetWithText(PSLongContentRow, tr(Strings.globalNounsEndpoint)), findsOneWidget);
    var edited = _latest();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => wireGuardSubpage(
          context,
          ModuleViewArgs(profileId: 'profile', module: edited, onChanged: (next) => edited = next),
          'peer-1-endpoint',
        )!,
      ),
    ));
    expect(find.byType(PSLongContentPage), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'vpn.example.org:443');
    await pumpHost(tester, edited);

    var module = _latest();
    var peer = WireGuardConfiguration(module: module).peers.single;
    expect(peer.keepAliveText, '60');
    expect(peer.endpoint, 'vpn.example.org:443');
    expect(module.value['configuration']['interface']['listenPort'], 51820);
    expect(_keyPaths(module.json), _keyPaths(original.json));
    expect(jsonDecode(jsonEncode(module.json)), module.json);
    expect(await engine.exportModule(module), contains('Endpoint = vpn.example.org:443'));

    // Add peer, then the button is disabled while the new peer has no key.
    await tester.tap(find.text(tr(Strings.modulesWireguardPeerAdd)));
    await tester.pumpAndSettle();
    expect(find.text(tr(Strings.modulesWireguardPeer, <Object>[2]).toUpperCase()), findsOneWidget);
    expect(WireGuardConfiguration(module: _latest()).canAddPeer, isFalse);
    await tester.tap(find.text(tr(Strings.modulesWireguardPeerAdd)));
    await tester.pumpAndSettle();
    expect(WireGuardConfiguration(module: _latest()).peers, hasLength(2));

    // Delete peer #1; the new one becomes #1.
    await tester.tap(find.text(tr(Strings.modulesWireguardPeerDelete)).first);
    await tester.pumpAndSettle();
    module = _latest();
    peer = WireGuardConfiguration(module: module).peers.single;
    expect(peer.publicKey, '');
    expect(find.text(tr(Strings.modulesWireguardPeer, <Object>[2]).toUpperCase()), findsNothing);
  });

  testWidgets('generate replaces the private key with a valid one', (tester) async {
    final original = await engine.importModule(conf, contextJson: wireGuardImportContext);
    await pumpHost(tester, original);
    await tester.tap(find.text(tr(Strings.modulesWireguardPrivateKeyGenerate)));
    await tester.pumpAndSettle();
    final privateKey = WireGuardConfiguration(module: _latest()).privateKey;
    expect(privateKey, isNot('4hBza7JtPKZFKwqtEmDR0iZyru1kqpQta/DRduMbHQw='));
    expect(base64.decode(privateKey), hasLength(32));
  });

  // Screenshots for review: WG_SHOT_DIR=/some/dir flutter test test/wireguard_view_test.dart
  final shotDir = io.Platform.environment['WG_SHOT_DIR'];
  testWidgets('screenshot', skip: shotDir == null, (tester) async {
    await tester.runAsync(() async {
      final fonts = '${io.Platform.environment['FLUTTER_ROOT'] ?? '/home/sigmadev/snap/flutter/common/flutter'}/bin/cache/artifacts/material_fonts';
      Future<void> load(String family, List<String> files) async {
        final loader = FontLoader(family);
        for (final file in files) {
          final bytes = io.File(file).readAsBytesSync();
          loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
        }
        await loader.load();
      }
      await load('Roboto', <String>['$fonts/Roboto-Regular.ttf', '$fonts/Roboto-Medium.ttf']);
      await load('MaterialIcons', <String>['$fonts/MaterialIcons-Regular.otf']);
      await load('monospace', <String>['/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf']);
    });
    final original = await engine.importModule(conf, contextJson: wireGuardImportContext);
    for (final brightness in Brightness.values) {
      await tester.binding.setSurfaceSize(const Size(420, 1900));
      await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey<String>('shot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: passepartoutTheme(brightness),
          home: _Host(initial: WireGuardConfiguration(module: original).addingPeer(), onModule: (_) {}),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey<String>('shot')));
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        io.File('$shotDir/wireguard-${brightness.name}.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    await tester.binding.setSurfaceSize(null);
  });
}

late TaggedModule Function() _latest;

Set<String> _keyPaths(Object? value, [String prefix = '']) => switch (value) {
      Map() => <String>{
          for (final entry in value.entries) ...<String>{
            '$prefix${entry.key}',
            ..._keyPaths(entry.value, '$prefix${entry.key}.'),
          },
        },
      List() => <String>{for (var i = 0; i < value.length; i++) ..._keyPaths(value[i], '$prefix$i.')},
      _ => const <String>{},
    };
