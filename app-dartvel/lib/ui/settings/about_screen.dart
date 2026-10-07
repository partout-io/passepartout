// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `LinksView` (About), `CreditsView`/`GenericCreditsView` (Credits),
// `VersionView` and `ChangelogView` (Version).
//
// Upstream pushes the license, notice and changelog pages without routes of
// their own. Here each has its own URL as a query on its parent page:
//   /settings/about/credits?license=<name>
//   /settings/about/credits?notice=<name>
//   /settings/version?changelog=1

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_log.dart';
import '../kit.dart';
import 'settings_support.dart';

/// `LinksView`. Shown as "About" in the route tree, titled "Links" as upstream.
class const AboutScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSScaffold(
        title: tr(Strings.viewsSettingsLinksTitle),
        body: PSForm(children: <Widget>[
          PSSection(header: tr(Strings.viewsSettingsLinksSectionsSupport), children: <Widget>[
            SettingsLinkRow(title: tr(Strings.viewsSettingsLinksRowsOpenDiscussion), url: SettingsConstants.discussionsUrl),
            // `WebDonationLink`: shown when there are no in-app purchases
            // and this is not a beta, which is this app on every platform.
            SettingsLinkRow(title: tr(Strings.viewsDonateTitle), url: SettingsConstants.donateUrl),
          ]),
          PSSection(header: tr(Strings.viewsSettingsLinksSectionsWeb), children: <Widget>[
            SettingsLinkRow(title: tr(Strings.viewsSettingsLinksRowsHomePage), url: SettingsConstants.homeUrl),
            SettingsLinkRow(title: tr(Strings.viewsSettingsLinksRowsBlog), url: SettingsConstants.blogUrl),
          ]),
          PSSection(children: <Widget>[
            SettingsLinkRow(title: tr(Strings.viewsSettingsLinksRowsDisclaimer), url: SettingsConstants.disclaimerUrl),
            SettingsLinkRow(title: tr(Strings.viewsSettingsLinksRowsPrivacyPolicy), url: SettingsConstants.privacyPolicyUrl),
          ]),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Credits

const String _licenseQuery = 'license';
const String _noticeQuery = 'notice';

/// Fetches a license text; replaceable in tests.
typedef TextFetcher = Future<String> Function(String url);

Future<String> fetchText(String url) async {
  final response = await Dio().get<String>(url, options: Options(responseType: .plain));
  return response.data ?? '';
}

/// `CreditsView`: licenses, notices and translators, from credits.json.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key, this.credits, this.query, this.fetcher = fetchText});

  /// Given in tests; otherwise read from the asset.
  final Credits? credits;

  /// The page query; read from the router when null.
  final Map<String, String>? query;

  final TextFetcher fetcher;

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  /// `contentForLicense`, kept for the life of the app as upstream's @State is
  /// for the life of the view.
  static final Map<String, String> _contentForLicense = <String, String>{};

  late Future<Credits> _credits = _load();

  Future<Credits> _load() async {
    if (widget.credits != null) return widget.credits!;
    try {
      return await Credits.load();
    } on Object catch (error) {
      AppLog.warning('Unable to load credits: $error');
      return const Credits();
    }
  }

  @override
  void didUpdateWidget(CreditsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.credits != widget.credits) _credits = _load();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.query ?? currentRouteQuery(context);
    return FutureBuilder<Credits>(
      future: _credits,
      builder: (context, snapshot) {
        final credits = snapshot.data;
        if (credits == null) {
          return PSScaffold(
            title: tr(Strings.viewsSettingsCreditsTitle),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final licenseName = query[_licenseQuery];
        final noticeName = query[_noticeQuery];
        for (final license in credits.licenses) {
          if (license.name == licenseName) {
            return _LicenseView(
              license: license,
              fetcher: widget.fetcher,
              cache: _contentForLicense,
            );
          }
        }
        for (final notice in credits.notices) {
          if (notice.name == noticeName) return _NoticeView(notice: notice);
        }
        return _CreditsList(credits: credits);
      },
    );
  }
}

class const _CreditsList({required final Credits credits}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSScaffold(
        title: tr(Strings.viewsSettingsCreditsTitle),
        body: PSForm(children: <Widget>[
          if (credits.licenses.isNotEmpty)
            PSSection(header: tr(Strings.viewsSettingsCreditsLicenses), children: <Widget>[
              for (final license in credits.sortedLicenses)
                PSRow(
                  title: license.name,
                  value: license.licenseName,
                  navigates: true,
                  onTap: () => pushRoute(DVRoutes.settingsaboutcredits.withQuery(<String, String>{_licenseQuery: license.name})),
                ),
            ]),
          if (credits.notices.isNotEmpty)
            PSSection(header: tr(Strings.viewsSettingsCreditsNotices), children: <Widget>[
              for (final notice in credits.sortedNotices)
                PSRow(
                  title: notice.name,
                  navigates: true,
                  onTap: () => pushRoute(DVRoutes.settingsaboutcredits.withQuery(<String, String>{_noticeQuery: notice.name})),
                ),
            ]),
          if (credits.translations.isNotEmpty)
            PSSection(header: tr(Strings.viewsSettingsCreditsTranslations), children: <Widget>[
              for (final code in credits.sortedLanguages)
                _TranslationRow(language: languageName(code), authors: credits.translations[code] ?? const <String>[]),
            ]),
        ]),
      );
}

class const _TranslationRow({required final String language, required final List<String> authors}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final secondary = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return ListTile(
      title: Text(language),
      trailing: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        children: <Widget>[for (final author in authors) Text(author, style: secondary)],
      ),
    );
  }
}

/// `GenericCreditsView.LicenseView`: the license text, fetched, monospaced.
class _LicenseView extends StatefulWidget {
  const _LicenseView({required this.license, required this.fetcher, required this.cache});

  final CreditsLicense license;
  final TextFetcher fetcher;
  final Map<String, String> cache;

  @override
  State<_LicenseView> createState() => _LicenseViewState();
}

class _LicenseViewState extends State<_LicenseView> {
  String? _content;

  @override
  void initState() {
    super.initState();
    _content = widget.cache[widget.license.name];
    if (_content == null) _loadUrl();
  }

  Future<void> _loadUrl() async {
    String content;
    try {
      content = await widget.fetcher(widget.license.licenseUrl);
      widget.cache[widget.license.name] = content;
    } on Object catch (error) {
      // Upstream shows the error's description in place of the text.
      content = '$error';
    }
    if (mounted) setState(() => _content = content);
  }

  @override
  Widget build(BuildContext context) => PSScaffold(
        title: widget.license.name,
        body: _content == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const .all(16),
                child: SelectableText(_content!, style: const TextStyle(fontFamily: 'monospace')),
              ),
      );
}

class const _NoticeView({required final CreditsNotice notice}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSScaffold(
        title: notice.name,
        body: Align(
          alignment: .topLeft,
          child: Padding(padding: const .all(16), child: SelectableText(notice.message)),
        ),
      );
}

// ---------------------------------------------------------------------------
// Version

const String _changelogQuery = 'changelog';

/// `VersionView`: logo, name, version, credit line and the CHANGELOG button.
class const VersionScreen({
  super.key,
  final Map<String, String>? query,
  final TextFetcher fetcher = fetchText,
  final String? partoutVersion,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = query ?? currentRouteQuery(context);
    if (current.containsKey(_changelogQuery)) return ChangelogScreen(fetcher: fetcher);
    final theme = Theme.of(context);
    return PSScaffold(
      title: tr(Strings.viewsSettingsTitle),
      body: SingleChildScrollView(
        padding: const .all(24),
        child: Column(children: <Widget>[
          Image.asset('assets/icon.png', width: 120, height: 120, semanticLabel: SettingsUnlocalized.appName,
              errorBuilder: (_, _, _) => const SizedBox.square(dimension: 120)),
          const SizedBox(height: 24),
          SelectableText(SettingsUnlocalized.appName, style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          SelectableText(
            SettingsBundle.versionString,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          SelectableText(
            tr(Strings.viewsVersionExtra, <Object>[SettingsUnlocalized.appName, SettingsUnlocalized.authorName]),
            textAlign: .center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => pushRoute(DVRoutes.settingsversion.withQuery(const <String, String>{_changelogQuery: '1'})),
            child: const Text(SettingsUnlocalized.changelog),
          ),
          const SizedBox(height: 24),
          // Not in upstream's VersionView: the engine version. VpnService does
          // not report it yet, so it shows a dash (see PROGRESS).
          PSSection(children: <Widget>[
            PSRow(title: SettingsUnlocalized.partout, value: partoutVersion ?? '—', monospaced: true),
          ]),
        ]),
      ),
    );
  }
}

/// `ChangelogView`: the build's CHANGELOG.txt, one row per entry, issue rows
/// open on GitHub.
class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key, this.fetcher = fetchText, this.build});

  final TextFetcher fetcher;

  /// The build whose changelog to load; this app has no build number yet.
  final String? build;

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  List<ChangelogEntry> _entries = const <ChangelogEntry>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    final build = widget.build ?? SettingsBundle.buildNumber?.toString();
    try {
      if (build != null) {
        _entries = ChangelogEntry.parseAll(await widget.fetcher(SettingsConstants.urlForChangelog(build)));
      }
    } on Object catch (error) {
      AppLog.error('CHANGELOG: Unable to load: $error');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) => PSScaffold(
        title: SettingsUnlocalized.changelog,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? PSEmptyMessage(text: tr(Strings.globalNounsNoContent))
                : PSForm(children: <Widget>[
                    PSSection(header: SettingsBundle.versionString, children: <Widget>[
                      for (final entry in _entries)
                        if (entry.issueUrl != null)
                          SettingsLinkRow(title: entry.comment, url: entry.issueUrl!)
                        else
                          PSRow(title: entry.comment),
                    ]),
                  ]),
      );
}
