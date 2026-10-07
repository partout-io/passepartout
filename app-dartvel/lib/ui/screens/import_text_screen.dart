// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// "/import-text": paste a profile (upstream `.importProfileText` modal,
// `ThemeTextInputView`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../kit.dart';

class ImportTextScreen extends StatefulWidget {
  const ImportTextScreen({super.key});

  @override
  State<ImportTextScreen> createState() => _ImportTextScreenState();
}

class _ImportTextScreenState extends State<ImportTextScreen> {
  final TextEditingController _text = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => _text.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    await runGuarded(context, () async {
      await ProfileStore.importText(_text.text, name: tr(Strings.placeholdersProfileImportedName));
      if (DV.Navigation.canGoBack) {
        DV.Navigation.back();
      } else {
        DV.Navigation.navigate(DVRoutes.index);
      }
    }, title: tr(Strings.globalActionsImport));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
        // Ctrl/Cmd+Enter submits; plain Enter is a newline in a profile.
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        },
        child: PSScaffold(
          title: tr(Strings.viewsAppToolbarImportTextTitle),
          actions: <Widget>[
            if (_busy)
              const Padding(padding: .all(12), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              TextButton(onPressed: _valid ? _submit : null, child: Text(tr(Strings.globalActionsImport))),
          ],
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const .all(16),
                child: Column(crossAxisAlignment: .stretch, children: <Widget>[
                  Text(tr(Strings.viewsAppToolbarImportTextCaption)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      autofocus: true,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: .circular(10), borderSide: BorderSide.none),
                        hintText: '[Interface]\nPrivateKey = …\n\n— or —\n\nclient\nremote vpn.example.com 1194',
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
