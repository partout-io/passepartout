// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/profile.dart';
import '../../../l10n/strings.g.dart';
import '../../../platform/vpn_service.dart';
import '../../kit.dart';

/// Shows an import dialog allowing the user to paste .ovpn configuration text
/// or load from a local file path.
/// Matches upstream `OpenVPNView+Import.swift` / `ModuleImportSection`.
Future<void> showOpenVPNImportDialog(
  BuildContext context, {
  required ValueChanged<TaggedModule> onImported,
  TaggedModule? currentModule,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _ImportDialog(
      onImported: onImported,
      currentModule: currentModule,
    ),
  );
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog({
    required this.onImported,
    this.currentModule,
  });

  final ValueChanged<TaggedModule> onImported;
  final TaggedModule? currentModule;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      _textController.text = data!.text!;
    }
  }

  Future<void> _loadFileFromPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (mounted) {
          _textController.text = content;
        }
      } else {
        if (mounted) {
          await showErrorAlert(
            context,
            title: tr(Strings.modulesGeneralRowsImportFromFile),
            message: 'File does not exist: $path',
          );
        }
      }
    } on Object catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: tr(Strings.modulesGeneralRowsImportFromFile),
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _doImport() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final imported = await VpnService.instance.importModule(text);
      if (!mounted) return;

      final base = widget.currentModule ?? TaggedModule.empty(ModuleType.openVPN);
      final nextValue = Map<String, dynamic>.from(base.value);

      // Merge imported configuration and credentials while preserving module identity
      if (imported.value['configuration'] != null) {
        nextValue['configuration'] = imported.value['configuration'];
      }
      if (imported.value['credentials'] != null) {
        nextValue['credentials'] = imported.value['credentials'];
      }
      if (imported.value['requiresInteractiveCredentials'] != null) {
        nextValue['requiresInteractiveCredentials'] =
            imported.value['requiresInteractiveCredentials'];
      }

      final merged = base.withValue(nextValue);
      widget.onImported(merged);

      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        await showErrorAlert(
          context,
          title: tr(Strings.modulesGeneralRowsImportFromFile),
          message: error.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(tr(Strings.modulesGeneralRowsImportFromFile)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      decoration: const InputDecoration(
                        labelText: 'File path',
                        hintText: '/path/to/profile.ovpn',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loadFileFromPath,
                    child: const Text('Load'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Configuration text (.ovpn)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.paste, size: 16),
                    label: const Text('Paste'),
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _textController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'client\nremote vpn.example.com 1194 udp\n...',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(tr(Strings.globalActionsCancel)),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _doImport,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(tr(Strings.globalActionsImport)),
        ),
      ],
    );
  }
}
