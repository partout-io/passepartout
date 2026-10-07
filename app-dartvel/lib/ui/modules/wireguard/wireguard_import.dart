// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Port of upstream `WireGuardView.ImportModifier` and `ModuleImportSection`:
// pick a wg-quick .conf file, parse it through the engine, and replace the
// module's configuration (the module keeps its id).

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../dartvel_client/dartvel_client.dart';
import '../../../domain/profile.dart';
import '../../../l10n/strings.g.dart';
import '../../../platform/vpn_service.dart';
import '../../kit.dart';
import '../module_view.dart';
import 'wireguard_configuration.dart';

/// Reads the text of a file the person picks; null when they cancel.
typedef WireGuardFileReader = Future<String?> Function();

Future<String?> _pickTextFile() async {
  final picked = await DV.Platform.fileStorage.pick();
  if (picked.isEmpty) return null;
  return utf8.decode(await picked.first.readBytes(), allowMalformed: true);
}

/// The file reader the import row uses. Tests replace it.
WireGuardFileReader wireGuardFileReader = _pickTextFile;

/// Upstream's `ModuleImportContext.WireGuard`.
const String wireGuardImportContext = '{"type":"WireGuard"}';

/// Parses [text] with the engine and returns [module] with its configuration.
Future<TaggedModule> importWireGuardConfiguration(TaggedModule module, String text) async {
  final imported = await VpnService.instance.importModule(text, contextJson: wireGuardImportContext);
  return WireGuardConfiguration(module: module).importing(imported);
}

/// `ModuleImportSection`: one "Import from file" button.
class const WireGuardImportSection({super.key, required final ModuleViewArgs args}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSSection(children: <Widget>[
        PSRow(
          title: tr(Strings.modulesGeneralRowsImportFromFile),
          onTap: () => runGuarded(
            context,
            () async {
              final text = await wireGuardFileReader();
              if (text == null) return;
              args.onChanged(await importWireGuardConfiguration(args.module, text));
            },
            title: args.module.typeLabel,
          ),
        ),
      ]);
}
