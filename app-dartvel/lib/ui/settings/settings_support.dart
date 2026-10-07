// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// What the Settings area shares: upstream's app constants (constants.json),
// the bundle version, the credits model (credits.json), the changelog entry
// parser, and how a row opens a link.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dartvel_client/dartvel_client.dart';

/// Upstream `Strings.Unlocalized`, kept literal as upstream does.
abstract final class SettingsUnlocalized {
  static const String appName = 'Passepartout';
  static const String authorName = 'Davide De Rosa (keeshux)';
  static const String changelog = 'CHANGELOG';
  static const String faq = 'FAQ';
  static const String partout = 'Partout';

  /// `Strings.Unlocalized.Issues.subject`, with this port's platform name.
  static const String issueSubject = '$appName/Dartvel - Report issue';
}

/// The app bundle: upstream's `ABI.AppBundle.versionString`.
///
/// The number is pubspec.yaml's `version:`. Dartvel generates no version
/// constant yet, so it is repeated here (see PROGRESS "Requests to lead").
abstract final class SettingsBundle {
  static const String versionNumber = '0.0.1';

  /// pubspec has no `+build` part, so there is no build number to show.
  static const int? buildNumber = null;

  static String get versionString =>
      buildNumber == null ? versionNumber : '$versionNumber ($buildNumber)';
}

/// Upstream `constants.json` (websites, github, emails) and the URLs
/// `Codegen+AppConstants.swift` derives from it.
abstract final class SettingsConstants {
  static const String partoutUrl = 'https://partout.io';
  static const String homeUrl = 'https://partout.io/passepartout';
  static const String discussionsUrl = 'https://github.com/orgs/partout-io/discussions';
  static const String issuesUrl = 'https://github.com/partout-io/passepartout/issues';
  static const String rawUrl = 'https://raw.githubusercontent.com/partout-io/passepartout';

  static const String blogUrl = '$partoutUrl/blog';
  static const String donateUrl = '$partoutUrl/donate';
  static const String disclaimerUrl = '$homeUrl/disclaimer';
  static const String faqUrl = '$homeUrl/faq';
  static const String privacyPolicyUrl = '$homeUrl/privacy';

  /// Where Report issue mails go: upstream's own address, kept 1:1.
  ///
  /// TODO(owner): choose the address for this fork. This is upstream's issue
  /// inbox; reports from this port land with upstream's author until changed.
  static const String issuesEmail = 'issues@passepartoutvpn.app';

  static String urlForIssue(int issue) => '$issuesUrl/$issue';

  static String urlForChangelog(String build) => '$rawUrl/refs/tags/builds/$build/app-apple/CHANGELOG.txt';
}

/// Opens [url] outside the app, the way upstream's `Link`/`ExternalLink` do.
///
/// Dartvel has no `DV.Platform` URL opener; `DVLinkOpener` is the funnel its
/// own external links use, so rows go through it too (see DARTVEL-GAPS.md).
void openExternalUrl(String url) => DVLinkOpener.open(url, newTab: true);

/// The query of the location on screen, or empty outside a router (tests).
///
/// Upstream pushes a detail view for a license, a notice or the changelog
/// without a route of its own. Here each detail has its own URL as a query
/// on the page it belongs to, so it deep-links and back/forward works.
Map<String, String> currentRouteQuery(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return const <String, String>{};
  return router.routerDelegate.currentConfiguration.uri.queryParameters;
}

/// Whether this is a desktop build: upstream's `#if os(macOS)` rows.
bool get isDesktopPlatform =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      .linux || .macOS || .windows => true,
      _ => false,
    };

// ---------------------------------------------------------------------------
// Credits (`ABI.Credits`, credits.json)

class const CreditsLicense({required final String name, required final String licenseName, required final String licenseUrl});

class const CreditsNotice({required final String name, required final String message});

class const Credits({
  final List<CreditsLicense> licenses = const <CreditsLicense>[],
  final List<CreditsNotice> notices = const <CreditsNotice>[],
  final Map<String, List<String>> translations = const <String, List<String>>{},
}) {
  factory Credits.fromJson(Map<String, dynamic> json) => Credits(
        licenses: <CreditsLicense>[
          for (final item in (json['licenses'] as List<dynamic>? ?? const <dynamic>[]).cast<Map<String, dynamic>>())
            CreditsLicense(
              name: item['name'] as String,
              licenseName: item['licenseName'] as String,
              licenseUrl: item['licenseURL'] as String,
            ),
        ],
        notices: <CreditsNotice>[
          for (final item in (json['notices'] as List<dynamic>? ?? const <dynamic>[]).cast<Map<String, dynamic>>())
            CreditsNotice(name: item['name'] as String, message: item['message'] as String),
        ],
        translations: <String, List<String>>{
          for (final entry in (json['translations'] as Map<String, dynamic>? ?? const <String, dynamic>{}).entries)
            entry.key: (entry.value as List<dynamic>).cast<String>(),
        },
      );

  /// The asset upstream's `Resources.credits` reads, copied unchanged.
  static const String assetPath = 'assets/credits/credits.json';

  static Future<Credits> load({AssetBundle? bundle}) async =>
      Credits.fromJson(jsonDecode(await (bundle ?? rootBundle).loadString(assetPath)) as Map<String, dynamic>);

  /// Sorted as `GenericCreditsView` sorts them: case-insensitive by name.
  List<CreditsLicense> get sortedLicenses =>
      <CreditsLicense>[...licenses]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<CreditsNotice> get sortedNotices =>
      <CreditsNotice>[...notices]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  /// Language codes sorted by their displayed name.
  List<String> get sortedLanguages =>
      translations.keys.toList()..sort((a, b) => languageName(a).compareTo(languageName(b)));
}

/// `String.localizedAsLanguageCode`: the language's own name, or the code.
///
/// Upstream names the language in the current locale through Foundation;
/// Dartvel has no locale display-name table, so each is named in itself.
String languageName(String code) => switch (code.split('-').first) {
      'de' => 'Deutsch',
      'el' => 'Ελληνικά',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'it' => 'Italiano',
      'nl' => 'Nederlands',
      'pl' => 'Polski',
      'pt' => 'Português',
      'ru' => 'Русский',
      'sv' => 'Svenska',
      'uk' => 'Українська',
      'zh' => '中文',
      _ => code,
    };

// ---------------------------------------------------------------------------
// Changelog (`ABI.ChangelogEntry`)

class const ChangelogEntry({required final int id, required final String comment, final int? issue}) {
  static const String entryPrefix = '*';

  /// `ChangelogEntry.init?(_:line:)`: `* Comment words (#123)`.
  static ChangelogEntry? parse(int index, String line) {
    if (!line.startsWith(entryPrefix)) return null;
    final words = line.split(' ').where((word) => word.isNotEmpty).toList()..removeAt(0);
    int? issue;
    if (words.length >= 2) {
      final last = words.last;
      if (last.startsWith('(#') && last.endsWith(')')) {
        final number = int.tryParse(last.substring(2, last.length - 1));
        if (number != null) {
          words.removeLast();
          issue = number;
        }
      }
    }
    return ChangelogEntry(id: index, comment: words.join(' '), issue: issue);
  }

  /// `GitHubReleaseStrategy.fetchChangelog`: one entry per `*` line.
  static List<ChangelogEntry> parseAll(String text) => <ChangelogEntry>[
        for (final (index, line) in text.split('\n').indexed) ?parse(index, line),
      ];

  String? get issueUrl => issue == null ? null : SettingsConstants.urlForIssue(issue!);
}

/// Pushes [target], keeping the page under it, as upstream's NavigationLink
/// does. Does nothing outside a router (widget tests).
void pushRoute(DVRouteTarget target) {
  if (DV.Navigation.isAttached) DV.Navigation.push<void>(target);
}

/// Upstream `Link`/`ExternalLink`: a row that opens [url] outside the app.
class const SettingsLinkRow({super.key, required final String title, required final String url}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
        link: true,
        child: ListTile(
          title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          trailing: Icon(Icons.open_in_new, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onTap: () => openExternalUrl(url),
        ),
      );
}
