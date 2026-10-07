// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `DiagnosticsView`, `ReportIssueButton` and `DebugLogView`.
//
// Sections, in upstream order:
//   Live log: App, Tunnel
//   Extensive logging, Include private data
//   Active profiles (only when a profile is active)
//   Tunnel: Remove tunnel logs + one row per saved tunnel log
//   Report issue
//
// Tunnel logs come from the tunnel-log workstream; until it lands the live
// tunnel log shows "No content" and the Tunnel section lists nothing.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_log.dart';
import '../../state/app_state.dart';
import '../kit.dart';
import 'settings_support.dart';

/// The query that picks which log [LiveLogScreen] shows.
const String logSourceQuery = 'source';
const String tunnelLogSource = 'tunnel';

/// A saved tunnel log (`ABI.LogEntry`). None exist until the tunnel-log
/// workstream provides them.
class const TunnelLogEntry({required final DateTime date, required final String path});

class const DiagnosticsScreen({super.key, final List<TunnelLogEntry> tunnelLogs = const <TunnelLogEntry>[]})
    extends StatelessWidget {
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
            onTap: () => pushRoute(DVRoutes.settingsdiagnosticslog.withQuery(
                const <String, String>{logSourceQuery: tunnelLogSource})),
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
            // Disabled while empty, as upstream; removal belongs to the
            // tunnel-log workstream.
            onTap: tunnelLogs.isEmpty ? null : () {},
          ),
          for (final entry in tunnelLogs)
            PSRow(title: _formatLogDate(context, entry.date), navigates: true),
        ]),
        const PSSection(children: <Widget>[ReportIssueButton()]),
      ]),
    );
  }
}

String _formatLogDate(BuildContext context, DateTime date) {
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(date)} '
      '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
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

/// `DebugLogView` + `DebugLogContentView`: the app log (or the tunnel log
/// with `?source=tunnel`), selectable, with copy, share and clear.
class const LiveLogScreen({super.key, final String? source}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isTunnel = (source ?? currentRouteQuery(context)[logSourceQuery]) == tunnelLogSource;
    final appLines = context.global<AppLogLines>().lines;
    // The tunnel's live log arrives with the tunnel-log workstream.
    final lines = isTunnel ? const <String>[] : <String>[for (final line in appLines) '$line'];
    final text = lines.join('\n');
    final theme = Theme.of(context);

    return PSScaffold(
      title: isTunnel ? tr(Strings.viewsDiagnosticsRowsTunnel) : tr(Strings.viewsDiagnosticsRowsApp),
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
        if (!isTunnel)
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
