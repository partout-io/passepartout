// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `DiagnosticsView`, `ReportIssueButton` and `DebugLogView`.
//
// Sections, in upstream order:
//   Live log: App, Tunnel
//   Extensive logging, Include private data
//   Active profiles (only when a profile is active)
//   Tunnel: Remove tunnel logs + one row per saved tunnel log, newest first
//   Report issue
//
// Log pages, each at its own URL:
//   /settings/diagnostics/log                           app log (live)
//   /settings/diagnostics/log?source=tunnel             newest tunnel log, re-read every second
//   /settings/diagnostics/log?source=tunnel&file=<name> one saved tunnel log

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_log.dart';
import '../../state/app_state.dart';
import '../kit.dart';
import 'settings_support.dart';
import 'tunnel_log_access.dart';

export 'tunnel_log_access.dart';

/// The queries that pick which log [LiveLogScreen] shows.
const String logSourceQuery = 'source';
const String logFileQuery = 'file';
const String tunnelLogSource = 'tunnel';

DVRouteTarget tunnelLogRoute([String? fileName]) => DVRoutes.settingsdiagnosticslog.withQuery(<String, String>{
      logSourceQuery: tunnelLogSource,
      logFileQuery: ?fileName,
    });

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.tunnelLogs = const TunnelLogAccess()});

  final TunnelLogAccess tunnelLogs;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<TunnelLogEntry> _tunnelLogs = const <TunnelLogEntry>[];

  @override
  void initState() {
    super.initState();
    _reloadTunnelLogs();
  }

  /// `computedTunnelLogs()`.
  Future<void> _reloadTunnelLogs() async {
    List<TunnelLogEntry> entries;
    try {
      entries = await widget.tunnelLogs.entries();
    } on Object catch (error) {
      AppLog.warning('Unable to list tunnel logs: $error');
      entries = const <TunnelLogEntry>[];
    }
    if (mounted) setState(() => _tunnelLogs = entries);
  }

  /// `removeTunnelLogs()`, after the confirmation every destructive action gets here.
  Future<void> _removeTunnelLogs() async {
    final title = tr(Strings.viewsDiagnosticsRowsRemoveTunnelLogs);
    if (!await confirmDestructive(context, title: title, action: title)) return;
    if (!mounted) return;
    await runGuarded(context, widget.tunnelLogs.deleteAll);
    await _reloadTunnelLogs();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context.global<Preferences>();
    final tunnel = context.global<TunnelState>();
    final profiles = context.global<ProfilesState>();
    void update(Preferences Function(Preferences) change) =>
        runGuarded(context, () => PreferencesStore.update(change));

    // `activeHeaders`: profiles the tunnel holds, sorted.
    final activeNames = <String>[
      if (tunnel.activeProfileId != null && tunnel.status != .disconnected)
        profiles.byId(tunnel.activeProfileId!)?.name ?? tunnel.activeProfileId!,
    ]..sort();

    return PSScaffold(
      title: tr(Strings.viewsDiagnosticsTitle),
      body: PSForm(children: <Widget>[
        PSSection(header: tr(Strings.viewsDiagnosticsSectionsLive), children: <Widget>[
          PSRow(
            title: tr(Strings.viewsDiagnosticsRowsApp),
            navigates: true,
            onTap: () => pushRoute(DVRoutes.settingsdiagnosticslog),
          ),
          PSRow(
            title: tr(Strings.viewsDiagnosticsRowsTunnel),
            navigates: true,
            onTap: () => pushRoute(tunnelLogRoute()),
          ),
        ]),
        PSSection(children: <Widget>[
          PSToggleRow(
            title: tr(Strings.viewsDiagnosticsRowsExtensiveLogging),
            subtitle: tr(Strings.viewsDiagnosticsRowsExtensiveLoggingSubtitle),
            value: preferences.extensiveLogging,
            onChanged: (value) => update((current) => current.copyWith(extensiveLogging: value)),
          ),
          PSToggleRow(
            title: tr(Strings.viewsDiagnosticsRowsIncludePrivateData),
            subtitle: tr(Strings.viewsDiagnosticsRowsIncludePrivateDataSubtitle),
            value: preferences.logsPrivateData,
            onChanged: (value) => update((current) => current.copyWith(logsPrivateData: value)),
          ),
        ]),
        if (activeNames.isNotEmpty)
          // Upstream links each to `DiagnosticsProfileView` (the OpenVPN
          // server configuration the tunnel received). The engine does not
          // report it yet, so the rows name the profiles only.
          PSSection(
            header: tr(Strings.viewsDiagnosticsSectionsActiveProfiles),
            children: <Widget>[for (final name in activeNames) PSRow(title: name)],
          ),
        PSSection(header: tr(Strings.viewsDiagnosticsSectionsTunnel), children: <Widget>[
          PSRow(
            title: tr(Strings.viewsDiagnosticsRowsRemoveTunnelLogs),
            destructive: _tunnelLogs.isNotEmpty,
            onTap: _tunnelLogs.isEmpty ? null : _removeTunnelLogs,
          ),
          for (final entry in _tunnelLogs)
            PSRow(
              title: tunnelLogTitle(context, entry),
              navigates: true,
              onTap: () => pushRoute(tunnelLogRoute(entry.name)),
            ),
        ]),
        const PSSection(children: <Widget>[ReportIssueButton()]),
      ]),
    );
  }
}

/// `appFormatter.string(from: item.date)`, or the file name without a date.
String tunnelLogTitle(BuildContext context, TunnelLogEntry entry) {
  final date = entry.date;
  if (date == null) return entry.name;
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(date)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)}';
}

/// `ReportIssueButton`: asks for a comment, then writes the email upstream
/// sends (issue.txt template) through `mailto:`, as upstream's fallback does
/// when it cannot compose mail itself. `mailto:` carries no attachments.
class ReportIssueButton extends StatefulWidget {
  const ReportIssueButton({super.key, this.title});

  final String? title;

  @override
  State<ReportIssueButton> createState() => _ReportIssueButtonState();
}

class _ReportIssueButtonState extends State<ReportIssueButton> {
  bool _isPending = false;

  Future<void> _report() async {
    final comment = await showDialog<String>(context: context, builder: (context) => const _ReportIssueCommentDialog());
    if (comment == null || comment.trim().isEmpty || !mounted) return;
    setState(() => _isPending = true);
    try {
      openExternalUrl(reportIssueMailto(comment.trim()));
    } finally {
      if (mounted) setState(() => _isPending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PSRow(
        title: widget.title ?? tr(Strings.viewsDiagnosticsReportIssueTitle),
        trailing: _isPending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : null,
        onTap: _isPending ? null : _report,
      );
}

class _ReportIssueCommentDialog extends StatefulWidget {
  const _ReportIssueCommentDialog();

  @override
  State<_ReportIssueCommentDialog> createState() => _ReportIssueCommentDialogState();
}

class _ReportIssueCommentDialogState extends State<_ReportIssueCommentDialog> {
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(tr(Strings.viewsDiagnosticsReportIssueTitle)),
        content: TextField(
          controller: _comment,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(labelText: tr(Strings.globalNounsComment)),
          onChanged: (_) => setState(() {}),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr(Strings.globalActionsCancel))),
          TextButton(
            onPressed: _comment.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_comment.text),
            child: Text(tr(Strings.globalActionsSend)),
          ),
        ],
      );
}

/// Upstream's issue.txt filled in, as a `mailto:` URL.
String reportIssueMailto(String comment) {
  final body = reportIssueBody(comment);
  return 'mailto:${SettingsConstants.issuesEmail}'
      '?subject=${Uri.encodeComponent(SettingsUnlocalized.issueSubject)}'
      '&body=${Uri.encodeComponent(body)}';
}

String reportIssueBody(String comment) {
  final os = kIsWeb ? 'web' : defaultTargetPlatform.name;
  return 'Hi,\n\n$comment\n\n--\n\n'
      'App: ${SettingsUnlocalized.appName} ${SettingsBundle.versionString} [dartvel]\n'
      'OS: $os\n'
      'Device: unknown\n'
      'Purchased: []\n\n--\n\nRegards';
}

// ---------------------------------------------------------------------------

/// `DebugLogView` + `DebugLogContentView`: the app log, or a tunnel log
/// (`?source=tunnel`, `&file=<name>`), selectable, with copy, share and clear.
class LiveLogScreen extends StatefulWidget {
  const LiveLogScreen({
    super.key,
    this.source,
    this.file,
    this.tunnelLogs = const TunnelLogAccess(),
    this.pollInterval = const Duration(seconds: 1),
  });

  /// `tunnel`, or null for the app log; read from the URL when null.
  final String? source;

  /// A saved tunnel log's name; read from the URL when null.
  final String? file;

  final TunnelLogAccess tunnelLogs;

  /// How often the live tunnel log is re-read.
  final Duration pollInterval;

  @override
  State<LiveLogScreen> createState() => _LiveLogScreenState();
}

class _LiveLogScreenState extends State<LiveLogScreen> {
  List<String> _tunnelLines = const <String>[];
  Timer? _poll;
  bool _isTunnel = false;
  bool _started = false;
  String? _file;
  TunnelLogEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final query = currentRouteQuery(context);
    _isTunnel = (widget.source ?? query[logSourceQuery]) == tunnelLogSource;
    _file = widget.file ?? query[logFileQuery];
    if (!_isTunnel) return;
    _readTunnelLog();
    // A saved log is read once, as upstream's `DebugLogView(withURL:)`; the
    // live one follows the newest file while this page is open.
    if (_file == null) _poll = Timer.periodic(widget.pollInterval, (_) => _readTunnelLog());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _readTunnelLog() async {
    try {
      final entry = _file == null ? (await widget.tunnelLogs.entries()).firstOrNull : await widget.tunnelLogs.byName(_file!);
      final lines = entry == null ? const <String>[] : await widget.tunnelLogs.lines(entry);
      if (!mounted) return;
      if (entry?.path != _entry?.path || !listEquals(lines, _tunnelLines)) {
        setState(() {
          _entry = entry;
          _tunnelLines = lines;
        });
      }
    } on Object catch (error) {
      AppLog.warning('Unable to read tunnel log: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLines = context.global<AppLogLines>().lines;
    final lines = _isTunnel ? _tunnelLines : <String>[for (final line in appLines) '$line'];
    final text = lines.join('\n');
    final theme = Theme.of(context);
    final title = !_isTunnel
        ? tr(Strings.viewsDiagnosticsRowsApp)
        : (_file != null && _entry != null)
            ? tunnelLogTitle(context, _entry!)
            : tr(Strings.viewsDiagnosticsRowsTunnel);

    return PSScaffold(
      title: title,
      actions: <Widget>[
        IconButton(
          // Upstream's copy button is an icon with no title string.
          tooltip: 'Copy',
          icon: const Icon(Icons.copy),
          onPressed: lines.isEmpty ? null : () => copyToClipboard(context, text),
        ),
        IconButton(
          tooltip: tr(Strings.globalActionsShare),
          icon: const Icon(Icons.share),
          onPressed: lines.isEmpty ? null : () => runGuarded(context, () => DV.Platform.share.shareText(text)),
        ),
        if (!_isTunnel)
          IconButton(
            tooltip: tr(Strings.globalActionsRemove),
            icon: const Icon(Icons.delete_outline),
            onPressed: lines.isEmpty ? null : AppLog.clear,
          ),
      ],
      body: lines.isEmpty
          ? PSEmptyMessage(text: tr(Strings.globalNounsNoContent))
          : Scrollbar(
              child: SingleChildScrollView(
                padding: const .all(16),
                child: SelectableText(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
    );
  }
}
