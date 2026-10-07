// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// WireGuard-only rows: "N entries" previews and `ThemeCopiableText` for the
// public key derived from the private key. Long-content rows and their pages
// are the kit's `PSLongContentRow` / `PSLongContentPage`.

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
