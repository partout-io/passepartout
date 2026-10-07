// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:io';

import 'tunnel_logs.dart';

export 'tunnel_logs.dart' show readTunnelLog, tunnelLogFiles;

/// Deletes [paths], each only if it is one of [tunnelLogFiles] (upstream's
/// `pspLogEntriesPurge` / `removeItem(at:)`).
Future<void> deleteTunnelLogs(Iterable<String> paths) async {
  final known = (await tunnelLogFiles()).toSet();
  for (final path in paths) {
    if (!known.contains(path)) continue;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
