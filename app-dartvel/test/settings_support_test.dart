// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/ui/settings/settings_support.dart';

void main() {
  test('credits.json decodes as upstream ships it', () {
    final json = jsonDecode(File('assets/credits/credits.json').readAsStringSync()) as Map<String, dynamic>;
    final credits = Credits.fromJson(json);
    expect(credits.licenses, hasLength((json['licenses'] as List<dynamic>).length));
    expect(credits.notices, hasLength((json['notices'] as List<dynamic>).length));
    expect(credits.translations.keys, containsAll(<String>['de', 'zh-Hans', 'pt-BR']));
    final names = credits.sortedLicenses.map((l) => l.name.toLowerCase()).toList();
    expect(names, List<String>.of(names)..sort());
    expect(credits.licenses.every((l) => l.licenseUrl.startsWith('https://')), isTrue);
  });

  test('asset is byte-identical to upstream credits.json', () {
    expect(
      File('assets/credits/credits.json').readAsStringSync(),
      File('../app-apple/Sources/AppResources/Resources/credits.json').readAsStringSync(),
    );
  });

  test('ChangelogEntry parses like upstream', () {
    final entry = ChangelogEntry.parse(3, '* OpenVPN: Restore support for inline auth-user-pass (#1959)')!;
    expect(entry.id, 3);
    expect(entry.comment, 'OpenVPN: Restore support for inline auth-user-pass');
    expect(entry.issue, 1959);
    expect(entry.issueUrl, 'https://github.com/partout-io/passepartout/issues/1959');
    expect(ChangelogEntry.parse(0, '* Plain entry')!.issue, isNull);
    expect(ChangelogEntry.parse(0, '* (#12)')!.comment, '(#12)');
    expect(ChangelogEntry.parse(0, 'Header line'), isNull);
    final all = ChangelogEntry.parseAll(File('../app-apple/CHANGELOG.txt').readAsStringSync());
    expect(all, isNotEmpty);
  });

  test('URLs derive from upstream constants.json', () {
    final constants = jsonDecode(File('../app-apple/Sources/AppResources/Resources/constants.json').readAsStringSync())
        as Map<String, dynamic>;
    final websites = constants['websites'] as Map<String, dynamic>;
    final github = constants['github'] as Map<String, dynamic>;
    final emails = constants['emails'] as Map<String, dynamic>;
    expect(SettingsConstants.homeUrl, websites['homeURL']);
    expect(SettingsConstants.partoutUrl, websites['partoutURL']);
    expect(SettingsConstants.faqUrl, '${websites['homeURL']}/faq');
    expect(SettingsConstants.donateUrl, '${websites['partoutURL']}/donate');
    expect(SettingsConstants.discussionsUrl, github['discussionsURL']);
    expect(SettingsConstants.issuesUrl, github['issuesURL']);
    expect(SettingsConstants.issuesEmail,
        '${(emails['recipients'] as Map<String, dynamic>)['issues']}@${emails['domain']}');
  });

  test('version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: (.+)$', multiLine: true).firstMatch(pubspec)!.group(1)!.trim(), SettingsBundle.versionNumber);
  });
}
