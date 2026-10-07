// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// The rows the WireGuard editor uses that the kit has no equivalent for yet:
// upstream `ThemeLongContentLink` (title + preview, opens a monospaced text
// editor page) and `ThemeCopiableText` for the derived public key.

import 'package:flutter/material.dart';

import '../../../l10n/strings.g.dart';
import '../../../platform/vpn_service.dart';
import '../../kit.dart';

/// Upstream `Int.localizedEntries`: nil for 0, "1 entry", "{0} entries".
String? localizedEntries(int count) => switch (count) {
      0 => null,
      1 => tr(Strings.globalNounsEntriesOne),
      _ => tr(Strings.globalNounsEntriesN, <Object>[count]),
    };

/// Upstream `String.asNumberOfEntries`: the number of comma-separated entries.
String? asNumberOfEntries(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return localizedEntries(1 + ','.allMatches(trimmed).length);
}

/// `ThemeLongContentLink`: a row showing [title] and a one-line preview that
/// opens an editor page for [text]. Each keystroke reports [onChanged].
class const WireGuardLongContentRow({
  super.key,
  required final String title,
  required final String text,
  required final ValueChanged<String> onChanged,
  final String? Function(String text)? preview,
  final TextInputType? keyboardType,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shown = preview == null ? text : preview!(text);
    return PSRow(
      title: title,
      value: (shown == null || shown.isEmpty) ? null : _middleTruncated(shown),
      monospaced: preview == null,
      navigates: true,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => WireGuardLongContentPage(
          title: title,
          text: text,
          onChanged: onChanged,
          keyboardType: keyboardType,
        ),
      )),
    );
  }
}

/// Upstream truncates the preview in the middle (`.truncationMode(.middle)`).
String _middleTruncated(String text, {int maxLength = 24}) {
  if (text.length <= maxLength) return text;
  final half = (maxLength - 1) ~/ 2;
  return '${text.substring(0, half)}…${text.substring(text.length - half)}';
}

/// `LongContentEditor`: a full-page, monospaced text editor.
class WireGuardLongContentPage extends StatefulWidget {
  const WireGuardLongContentPage({
    super.key,
    required this.title,
    required this.text,
    required this.onChanged,
    this.keyboardType,
  });

  final String title;
  final String text;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  State<WireGuardLongContentPage> createState() => _WireGuardLongContentPageState();
}

class _WireGuardLongContentPageState extends State<WireGuardLongContentPage> {
  late final TextEditingController _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PSScaffold(
        title: widget.title,
        body: Padding(
          padding: const .all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            expands: true,
            maxLines: null,
            keyboardType: widget.keyboardType ?? TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            textAlignVertical: .top,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(border: InputBorder.none, semanticCounterText: widget.title),
            onChanged: widget.onChanged,
          ),
        ),
      );
}

/// `ThemeCopiableText(publicKey, value: keyGenerator.publicKey(for: privateKey))`:
/// the public key derived from [privateKey] by the engine; empty when invalid.
class WireGuardPublicKeyRow extends StatefulWidget {
  const WireGuardPublicKeyRow({super.key, required this.privateKey});

  final String privateKey;

  @override
  State<WireGuardPublicKeyRow> createState() => _WireGuardPublicKeyRowState();
}

class _WireGuardPublicKeyRowState extends State<WireGuardPublicKeyRow> {
  String _publicKey = '';
  String? _derivedFrom;

  @override
  void initState() {
    super.initState();
    _derive();
  }

  @override
  void didUpdateWidget(WireGuardPublicKeyRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.privateKey != widget.privateKey) _derive();
  }

  Future<void> _derive() async {
    final privateKey = widget.privateKey;
    _derivedFrom = privateKey;
    var publicKey = '';
    if (privateKey.isNotEmpty) {
      try {
        publicKey = await VpnService.instance.wireGuardPublicKey(privateKey);
      } on Object {
        publicKey = '';
      }
    }
    if (!mounted || _derivedFrom != privateKey) return;
    setState(() => _publicKey = publicKey);
  }

  @override
  Widget build(BuildContext context) => PSRow(
        title: tr(Strings.globalNounsPublicKey),
        subtitle: _publicKey.isEmpty ? null : _publicKey,
        monospaced: true,
        selectable: true,
        onTap: _publicKey.isEmpty ? null : () => copyToClipboard(context, _publicKey),
        trailing: _publicKey.isEmpty
            ? null
            : Icon(Icons.copy, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}
