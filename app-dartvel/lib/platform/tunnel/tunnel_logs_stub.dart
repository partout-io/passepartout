// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Targets without dart:io (web): no tunnel runs here, so there are no logs.

Future<List<String>> tunnelLogFiles() async => const <String>[];

Future<String> readTunnelLog(String path) async => throw ArgumentError('Not a tunnel log');

Future<void> deleteTunnelLogs(Iterable<String> paths) async {}
