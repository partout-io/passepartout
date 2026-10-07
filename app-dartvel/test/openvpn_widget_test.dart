// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/platform/vpn_service_native.dart';
import 'package:passepartout/ui/kit.dart';
import 'package:passepartout/ui/modules/module_view.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_content_screen.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_credentials_screen.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_formatters.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_import_dialog.dart';
import 'package:passepartout/ui/modules/openvpn/openvpn_remotes_screen.dart';
import 'package:passepartout/ui/modules/openvpn_view.dart';

Widget _buildTestApp(Widget child) => MaterialApp(
      theme: passepartoutTheme(Brightness.light),
      home: Scaffold(
        body: child,
      ),
    );

void main() {
  final engine = PartoutVpnService();

  group('OpenVPN Sections Rendering', () {
    testWidgets('renders import section when configuration is empty', (tester) async {
      final module = TaggedModule.empty(ModuleType.openVPN);
      var changedCount = 0;
      final args = ModuleViewArgs(
        profileId: 'test-profile',
        module: module,
        onChanged: (_) => changedCount++,
      );

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ListView(
              children: openVPNSections(context, args),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tr(Strings.modulesGeneralRowsImportFromFile)), findsOneWidget);
      expect(changedCount, 0);
    });

    testWidgets('renders all upstream sections for imported protonvpn.ovpn fixture', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final path = '/home/sigmadev/passepartout/partout/tests/openvpn/fixtures/protonvpn.ovpn';
      final text = File(path).readAsStringSync();
      final module = await engine.importModule(text);

      var changedCount = 0;
      final args = ModuleViewArgs(
        profileId: 'test-profile',
        module: module,
        onChanged: (_) => changedCount++,
      );

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ListView(
              children: openVPNSections(context, args),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Import row present
      expect(find.text(tr(Strings.modulesGeneralRowsImportFromFile)), findsOneWidget);

      // Connection section & Remotes
      expect(find.text(tr(Strings.globalNounsConnection).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnRemotes)), findsOneWidget);
      expect(find.text(formatEntriesCount(5)!), findsOneWidget);

      // Account section & Credentials
      expect(find.text(tr(Strings.globalNounsAccount).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnCredentials)), findsOneWidget);

      // Communication section
      expect(find.text(tr(Strings.modulesOpenvpnCommunication).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnCipher)), findsOneWidget);
      expect(find.text('AES-256-CBC'), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnDigest)), findsOneWidget);
      expect(find.text('SHA512'), findsOneWidget);
      expect(find.text('XOR'), findsOneWidget);
      expect(find.text('obfuscate'), findsOneWidget);

      // TLS section
      expect(find.text('TLS'), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnTlsWrap)), findsOneWidget);
      expect(find.text('--tls-auth'), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnEku)), findsOneWidget);

      // Other section
      expect(find.text(tr(Strings.globalNounsOther).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnRandomizeEndpoint)), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnRenegotiation)), findsOneWidget);
    });
  });

  group('OpenVPN Sub-Screens & Editing', () {
    testWidgets('OpenVPNCredentialsScreen updates credentials and interactive OTP', (tester) async {
      final module = TaggedModule.of(ModuleType.openVPN, <String, dynamic>{
        'id': 'test-openvpn-module',
        'configuration': <String, dynamic>{'authUserPass': true},
        'credentials': <String, dynamic>{
          'username': 'old-user',
          'password': 'old-password',
          'otpMethod': 'none',
        },
        'requiresInteractiveCredentials': false,
        'customFieldToPreserve': 'custom-123',
      });

      TaggedModule? updatedModule;
      await tester.pumpWidget(
        _buildTestApp(
          OpenVPNCredentialsScreen(
            module: module,
            onChanged: (m) => updatedModule = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check initial values
      expect(find.text('old-user'), findsOneWidget);
      expect(find.text(tr(Strings.modulesOpenvpnCredentialsInteractive)), findsOneWidget);

      // Toggle interactive credentials
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(updatedModule, isNotNull);
      expect(updatedModule!.value['requiresInteractiveCredentials'], true);
      // Ensure customFieldToPreserve is kept
      expect(updatedModule!.value['customFieldToPreserve'], 'custom-123');

      // Edit username
      await tester.enterText(find.widgetWithText(TextField, 'old-user'), 'new-user');
      await tester.pumpAndSettle();

      expect((updatedModule!.value['credentials'] as Map)['username'], 'new-user');
    });

    testWidgets('OpenVPNRemotesScreen allows adding, editing and deleting remotes', (tester) async {
      final module = TaggedModule.of(ModuleType.openVPN, <String, dynamic>{
        'id': 'test-openvpn-module',
        'configuration': <String, dynamic>{
          'remotes': <dynamic>['vpn.example.com:UDP:1194'],
          'customEngineKey': 999,
        },
      });

      TaggedModule? updatedModule;
      await tester.pumpWidget(
        _buildTestApp(
          OpenVPNRemotesScreen(
            module: module,
            onChanged: (m) => updatedModule = m,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 1 remote
      expect(find.text('vpn.example.com:1194'), findsOneWidget);

      // Add a remote
      await tester.tap(find.text(tr(Strings.globalActionsAdd)));
      await tester.pumpAndSettle();

      expect(updatedModule, isNotNull);
      final remotes = (updatedModule!.value['configuration'] as Map)['remotes'] as List;
      expect(remotes, hasLength(2));
      // Preserved customEngineKey
      expect((updatedModule!.value['configuration'] as Map)['customEngineKey'], 999);

      // Delete the first remote
      await tester.tap(find.byIcon(Icons.remove_circle).first);
      await tester.pumpAndSettle();

      final remotesAfterDelete =
          (updatedModule!.value['configuration'] as Map)['remotes'] as List;
      expect(remotesAfterDelete, hasLength(1));
    });

    testWidgets('OpenVPNContentScreen renders content with copy action', (tester) async {
      const content = '-----BEGIN CERTIFICATE-----\nABC123\n-----END CERTIFICATE-----';
      await tester.pumpWidget(
        _buildTestApp(
          const OpenVPNContentScreen(
            title: 'CA Certificate',
            content: content,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CA Certificate'), findsOneWidget);
      expect(find.text(content), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    test('edit round-trips JSON via TunnelProfile without losing fields', () async {
      final text = File('test/fixtures/sample.ovpn').readAsStringSync();
      final module = await engine.importModule(text);

      // Verify and edit credentials
      final withCreds = module.withField('credentials', <String, dynamic>{
        'username': 'sigma',
        'password': 'secret-password',
        'otpMethod': 'append',
      }).withField('requiresInteractiveCredentials', true);

      // Wrap in profile
      var profile = TunnelProfile.empty('RoundTrip Profile').savingModule(withCreds);

      // Round-trip encode -> decode
      final encoded = profile.encode();
      final decoded = TunnelProfile.decode(encoded);

      final roundtrippedModule = decoded.module(withCreds.id)!;
      final roundtrippedCreds = roundtrippedModule.value['credentials'] as Map;
      expect(roundtrippedCreds['username'], 'sigma');
      expect(roundtrippedCreds['password'], 'secret-password');
      expect(roundtrippedCreds['otpMethod'], 'append');
      expect(roundtrippedModule.value['requiresInteractiveCredentials'], true);

      // Verify configuration is completely preserved
      final config = roundtrippedModule.value['configuration'] as Map;
      expect(config['remotes'], contains('vpn.example.com:UDP:1194'));
      expect(config['authUserPass'], true);
      expect(config['ca'], contains('BEGIN CERTIFICATE'));
    });
    testWidgets('showOpenVPNImportDialog imports valid .ovpn text and calls onImported', (tester) async {
      final module = TaggedModule.empty(ModuleType.openVPN);
      TaggedModule? importedModule;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showOpenVPNImportDialog(
                context,
                currentModule: module,
                onImported: (m) => importedModule = m,
              ),
              child: const Text('Open Import'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Import'));
      await tester.pumpAndSettle();

      expect(find.text(tr(Strings.modulesGeneralRowsImportFromFile)), findsOneWidget);

      final ovpnText = File('test/fixtures/sample.ovpn').readAsStringSync();
      await tester.enterText(find.byType(TextField).last, ovpnText);
      await tester.pumpAndSettle();

      await tester.tap(find.text(tr(Strings.globalActionsImport)));
      await tester.pumpAndSettle();

      expect(importedModule, isNotNull);
      expect(importedModule!.type, 'OpenVPN');
      final config = importedModule!.value['configuration'] as Map;
      expect(config['remotes'], contains('vpn.example.com:UDP:1194'));
    });
  });
}
