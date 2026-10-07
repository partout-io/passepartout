// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/state/app_log.dart';
import 'package:passepartout/state/app_state.dart';
import 'package:passepartout/state/profile_draft.dart';
import 'package:passepartout/ui/kit.dart';
import 'package:passepartout/ui/settings/about_screen.dart';
import 'package:passepartout/ui/settings/diagnostics_screen.dart';
import 'package:passepartout/ui/settings/preferences_screen.dart';
import 'package:passepartout/ui/settings/settings_screen.dart';
import 'package:passepartout/ui/settings/settings_support.dart';

/// main.dart's init order, without the app.
void initGlobals() {
  const DVI18n().loadAll(stringCatalogs.values);
  const DVI18n().useLocale(const LocaleTag('en'));
  AppLog.init();
  ProfileStore.init();
  TunnelStore.init();
  PreferencesStore.init();
  DraftStore.init();
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(theme: passepartoutTheme(.light), home: screen));
  await tester.pump();
}

Credits upstreamCredits() => Credits.fromJson(
    jsonDecode(File('assets/credits/credits.json').readAsStringSync()) as Map<String, dynamic>);

void main() {
  setUp(initGlobals);

  group('SettingsScreen', () {
    testWidgets('mobile layout has upstream iOS rows and sections', (tester) async {
      await pumpScreen(tester, const SettingsScreen(desktopLayout: false));
      expect(find.text(tr(Strings.globalNounsSettings)), findsOneWidget);
      for (final title in <String>[
        tr(Strings.globalNounsPreferences),
        tr(Strings.globalNounsVersion),
        tr(Strings.viewsSettingsLinksTitle),
        tr(Strings.viewsSettingsCreditsTitle),
        'FAQ',
        tr(Strings.viewsDiagnosticsTitle),
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text(tr(Strings.globalNounsAbout).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.globalNounsTroubleshooting).toUpperCase()), findsOneWidget);
      // iOS shows the version as the Version row's trailing value.
      expect(find.text(SettingsBundle.versionString), findsOneWidget);
      // Row order: Preferences above Version above Links above Diagnostics.
      final top = <double>[
        for (final title in <String>[
          tr(Strings.globalNounsPreferences),
          tr(Strings.globalNounsVersion),
          tr(Strings.viewsSettingsLinksTitle),
          tr(Strings.viewsSettingsCreditsTitle),
          'FAQ',
          tr(Strings.viewsDiagnosticsTitle),
        ])
          tester.getTopLeft(find.text(title)).dy,
      ];
      expect(top, List<double>.of(top)..sort());
    });

    testWidgets('desktop layout follows upstream macOS grouping', (tester) async {
      await pumpScreen(tester, const SettingsScreen(desktopLayout: true));
      expect(find.text(tr(Strings.viewsSettingsTitle)), findsOneWidget);
      // Version moves under About, the version string sits under the list.
      expect(find.text(SettingsBundle.versionString), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(tr(Strings.globalNounsAbout).toUpperCase())).dy,
        lessThan(tester.getTopLeft(find.text(tr(Strings.globalNounsVersion))).dy),
      );
    });
  });

  group('PreferencesScreen', () {
    testWidgets('shows upstream rows; desktop-only rows only on desktop', (tester) async {
      await pumpScreen(tester, const PreferencesScreen(desktopLayout: false));
      expect(find.text(tr(Strings.viewsPreferencesSystemAppearance)), findsOneWidget);
      expect(find.text(tr(Strings.viewsPreferencesPinsActiveProfile)), findsOneWidget);
      expect(find.text(tr(Strings.viewsPreferencesDnsFallsBack)), findsOneWidget);
      expect(find.text(tr(Strings.viewsPreferencesDnsFallsBackFooter)), findsOneWidget);
      expect(find.text(tr(Strings.viewsPreferencesKeepsInMenu)), findsNothing);
      expect(find.text(tr(Strings.viewsPreferencesLaunchesOnLogin)), findsNothing);

      await pumpScreen(tester, const PreferencesScreen(desktopLayout: true));
      expect(find.text(tr(Strings.viewsPreferencesKeepsInMenu)), findsOneWidget);
      expect(find.text(tr(Strings.viewsPreferencesLaunchesOnLogin)), findsOneWidget);
    });

    testWidgets('platform detection matches upstream #if os(macOS)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(isDesktopPlatform, isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(isDesktopPlatform, isTrue);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('toggles write PreferencesStore', (tester) async {
      await pumpScreen(tester, const PreferencesScreen(desktopLayout: true));
      final before = PreferencesStore.state;
      for (final key in <DVTranslationKey>[
        Strings.viewsPreferencesLaunchesOnLogin,
        Strings.viewsPreferencesKeepsInMenu,
        Strings.viewsPreferencesPinsActiveProfile,
        Strings.viewsPreferencesDnsFallsBack,
      ]) {
        await tester.runAsync(() async {
          await tester.tap(find.text(tr(key)));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }
      final after = PreferencesStore.state;
      expect(after.launchesOnLogin, !before.launchesOnLogin);
      expect(after.keepsInMenu, !before.keepsInMenu);
      expect(after.pinsActiveProfile, !before.pinsActiveProfile);
      expect(after.dnsFallsBack, !before.dnsFallsBack);
      // The switches show the new values.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).map((s) => s.value).toList();
      expect(switches, <bool>[after.launchesOnLogin, after.keepsInMenu, after.pinsActiveProfile, after.dnsFallsBack]);
    });

    testWidgets('appearance picker writes PreferencesStore', (tester) async {
      await pumpScreen(tester, const PreferencesScreen(desktopLayout: false));
      expect(find.text(tr(Strings.entitiesUiSystemAppearanceSystem)), findsOneWidget);
      await tester.tap(find.text(tr(Strings.viewsPreferencesSystemAppearance)));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text(tr(Strings.entitiesUiSystemAppearanceDark)).last);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(PreferencesStore.state.appearance, SystemAppearance.dark);
    });
  });

  group('DiagnosticsScreen', () {
    testWidgets('shows upstream sections and logging toggles', (tester) async {
      await pumpScreen(tester, const DiagnosticsScreen());
      for (final key in <DVTranslationKey>[
        Strings.viewsDiagnosticsRowsApp,
        Strings.viewsDiagnosticsRowsTunnel,
        Strings.viewsDiagnosticsRowsExtensiveLogging,
        Strings.viewsDiagnosticsRowsIncludePrivateData,
        Strings.viewsDiagnosticsRowsRemoveTunnelLogs,
        Strings.viewsDiagnosticsReportIssueTitle,
      ]) {
        expect(find.text(tr(key)), findsOneWidget, reason: tr(key));
      }
      expect(find.text(tr(Strings.viewsDiagnosticsSectionsLive).toUpperCase()), findsOneWidget);
      expect(find.text(tr(Strings.viewsDiagnosticsSectionsTunnel).toUpperCase()), findsOneWidget);
      // No active profile, no Active profiles section.
      expect(find.text(tr(Strings.viewsDiagnosticsSectionsActiveProfiles).toUpperCase()), findsNothing);

      final before = PreferencesStore.state;
      for (final key in <DVTranslationKey>[
        Strings.viewsDiagnosticsRowsExtensiveLogging,
        Strings.viewsDiagnosticsRowsIncludePrivateData,
      ]) {
        await tester.runAsync(() async {
          await tester.tap(find.text(tr(key)));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pump();
      }
      expect(PreferencesStore.state.extensiveLogging, !before.extensiveLogging);
      expect(PreferencesStore.state.logsPrivateData, !before.logsPrivateData);
    });

    testWidgets('report issue asks for a comment', (tester) async {
      await pumpScreen(tester, const DiagnosticsScreen());
      await tester.tap(find.text(tr(Strings.viewsDiagnosticsReportIssueTitle)));
      await tester.pumpAndSettle();
      expect(find.text(tr(Strings.globalNounsComment)), findsOneWidget);
      final send = find.widgetWithText(TextButton, tr(Strings.globalActionsSend));
      expect(tester.widget<TextButton>(send).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'It drops');
      await tester.pump();
      expect(tester.widget<TextButton>(send).onPressed, isNotNull);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    test('report issue mail carries upstream template', () {
      final url = Uri.parse(reportIssueMailto('It drops'));
      expect(url.scheme, 'mailto');
      expect(url.path, SettingsConstants.issuesEmail);
      expect(url.queryParameters['subject'], 'Passepartout/Dartvel - Report issue');
      expect(url.queryParameters['body'], contains('Hi,\n\nIt drops\n\n--\n\nApp: Passepartout 0.0.1'));
    });
  });

  group('LiveLogScreen', () {
    testWidgets('lists app log lines as selectable text and clears', (tester) async {
      AppLog.info('first line');
      AppLog.error('second line');
      await pumpScreen(tester, const LiveLogScreen());
      expect(find.text(tr(Strings.viewsDiagnosticsRowsApp)), findsOneWidget);
      final text = tester.widget<SelectableText>(find.byType(SelectableText)).data!;
      expect(text, contains('[info] first line'));
      expect(text, contains('[error] second line'));
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip(tr(Strings.globalActionsShare)), findsOneWidget);

      await tester.tap(find.byTooltip(tr(Strings.globalActionsRemove)));
      await tester.pump();
      expect(AppLog.lines, isEmpty);
      expect(find.text(tr(Strings.globalNounsNoContent)), findsOneWidget);
    });

    testWidgets('tunnel log is empty until the tunnel-log workstream lands', (tester) async {
      AppLog.info('app only');
      await pumpScreen(tester, const LiveLogScreen(source: tunnelLogSource));
      expect(find.text(tr(Strings.viewsDiagnosticsRowsTunnel)), findsOneWidget);
      expect(find.text(tr(Strings.globalNounsNoContent)), findsOneWidget);
    });
  });

  group('About', () {
    testWidgets('Links rows match upstream LinksView', (tester) async {
      await pumpScreen(tester, const AboutScreen());
      expect(find.text(tr(Strings.viewsSettingsLinksTitle)), findsOneWidget);
      for (final key in <DVTranslationKey>[
        Strings.viewsSettingsLinksRowsOpenDiscussion,
        Strings.viewsDonateTitle,
        Strings.viewsSettingsLinksRowsHomePage,
        Strings.viewsSettingsLinksRowsBlog,
        Strings.viewsSettingsLinksRowsDisclaimer,
        Strings.viewsSettingsLinksRowsPrivacyPolicy,
      ]) {
        expect(find.text(tr(key)), findsOneWidget, reason: tr(key));
      }
    });

    testWidgets('Credits lists licenses, notices and translations', (tester) async {
      final credits = upstreamCredits();
      await pumpScreen(tester, CreditsScreen(credits: credits, query: const <String, String>{}));
      await tester.pump();
      expect(find.text(tr(Strings.viewsSettingsCreditsLicenses).toUpperCase()), findsOneWidget);
      expect(find.text(credits.sortedLicenses.first.name), findsOneWidget);
      await tester.scrollUntilVisible(find.text(tr(Strings.viewsSettingsCreditsNotices).toUpperCase()), 300);
      expect(find.text(credits.sortedNotices.first.name), findsOneWidget);
      await tester.scrollUntilVisible(find.text(tr(Strings.viewsSettingsCreditsTranslations).toUpperCase()), 300);
      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('Credits license page fetches the text', (tester) async {
      final credits = upstreamCredits();
      final license = credits.licenses.first;
      String? fetched;
      await pumpScreen(
        tester,
        CreditsScreen(
          credits: credits,
          query: <String, String>{'license': license.name},
          fetcher: (url) async {
            fetched = url;
            return 'MIT License text';
          },
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(fetched, license.licenseUrl);
      expect(find.text(license.name), findsOneWidget);
      expect(find.text('MIT License text'), findsOneWidget);
    });

    testWidgets('Credits notice page shows the message', (tester) async {
      final credits = upstreamCredits();
      final notice = credits.notices.first;
      await pumpScreen(tester, CreditsScreen(credits: credits, query: <String, String>{'notice': notice.name}));
      await tester.pump();
      expect(find.text(notice.message), findsOneWidget);
    });

    testWidgets('Version shows name, version, credit line, changelog and Partout', (tester) async {
      await pumpScreen(tester, const VersionScreen(query: <String, String>{}));
      expect(find.text('Passepartout'), findsOneWidget);
      expect(find.text(SettingsBundle.versionString), findsOneWidget);
      expect(find.text(tr(Strings.viewsVersionExtra, <Object>['Passepartout', 'Davide De Rosa (keeshux)'])), findsOneWidget);
      expect(find.text('CHANGELOG'), findsOneWidget);
      expect(find.text('Partout'), findsOneWidget);
    });

    testWidgets('Changelog lists entries, issue rows link to GitHub', (tester) async {
      await pumpScreen(
        tester,
        ChangelogScreen(build: '4000', fetcher: (url) async => '* Fix A (#12)\n* Fix B\nnot an entry'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Fix A'), findsOneWidget);
      expect(find.text('Fix B'), findsOneWidget);
      expect(find.byType(SettingsLinkRow), findsOneWidget);
    });

    testWidgets('Changelog without a build shows no content', (tester) async {
      await pumpScreen(tester, const VersionScreen(query: <String, String>{'changelog': '1'}));
      await tester.pump();
      expect(find.text(tr(Strings.globalNounsNoContent)), findsOneWidget);
    });
  });
}
