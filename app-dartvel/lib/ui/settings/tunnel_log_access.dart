// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The tunnel's saved logs as Diagnostics sees them (upstream `ABI.LogEntry`
// and `pspLogEntriesAvailable`/`pspLogEntriesPurge`). The file functions come
// from the platform facade; tests pass their own.

import '../../platform/tunnel/tunnel_logs_facade.dart' as files;

/// One saved tunnel log: `<microseconds since epoch>.log`.
class const TunnelLogEntry({required final String path}) {
  /// The file name, which is also its id in the URL.
  String get name => path.split(RegExp(r'[/\\]')).last;

  /// When the tunnel started writing it, from the file name.
  DateTime? get date {
    final stem = name.endsWith('.log') ? name.substring(0, name.length - 4) : name;
    final micros = int.tryParse(stem);
    return micros == null ? null : DateTime.fromMicrosecondsSinceEpoch(micros);
  }
}

class const TunnelLogAccess({
  final Future<List<String>> Function() listFiles = files.tunnelLogFiles,
  final Future<String> Function(String path) readFile = files.readTunnelLog,
  final Future<void> Function(Iterable<String> paths) deleteFiles = files.deleteTunnelLogs,
}) {
  /// Newest first.
  Future<List<TunnelLogEntry>> entries() async {
    final list = <TunnelLogEntry>[for (final path in await listFiles()) TunnelLogEntry(path: path)];
    list.sort((a, b) {
      final left = a.date, right = b.date;
      if (left != null && right != null) return right.compareTo(left);
      return b.name.compareTo(a.name);
    });
    return list;
  }

  Future<TunnelLogEntry?> byName(String name) async {
    for (final entry in await entries()) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  Future<List<String>> lines(TunnelLogEntry entry) async =>
      (await readFile(entry.path)).split('\n').where((line) => line.isNotEmpty).toList();

  Future<void> deleteAll() async => deleteFiles(<String>[for (final entry in await entries()) entry.path]);
}
