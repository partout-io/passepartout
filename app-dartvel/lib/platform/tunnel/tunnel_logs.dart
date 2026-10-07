// SPDX-License-Identifier: GPL-3.0
import 'dart:io';

Directory tunnelLogDirectory() => Directory(
  '${Platform.environment['XDG_CACHE_HOME'] ?? '${Platform.environment['HOME'] ?? Directory.systemTemp.path}/.cache'}/passepartout/tunnel',
);
Future<List<String>> tunnelLogFiles() async {
  final dir = tunnelLogDirectory();
  if (!await dir.exists()) return [];
  final files = await dir
      .list(followLinks: false)
      .where((e) => e is File && e.path.endsWith('.log'))
      .map((e) => e.path)
      .toList();
  files.sort((a, b) => b.compareTo(a));
  return files;
}

Future<String> readTunnelLog(String path) async {
  if (!(await tunnelLogFiles()).contains(path)) {
    throw ArgumentError('Not a tunnel log');
  }
  return File(path).readAsString();
}
