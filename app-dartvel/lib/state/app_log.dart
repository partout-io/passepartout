// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/foundation.dart';

import '../dartvel_client/dartvel_client.dart';

/// One line of the app log, as Diagnostics > Live log shows it.
class const LogLine({required final DateTime time, required final String level, required final String message}) {
  @override
  String toString() => '${time.toIso8601String()} [$level] $message';
}

/// The app's in-memory log (last [capacity] lines), held in `DV.global` so
/// Diagnostics rebuilds as lines arrive. Partout's own logger feeds it too.
abstract final class AppLog {
  static const int capacity = 2000;

  static List<LogLine> get lines => DV.global<AppLogLines>().lines;

  static void init() => DV.global<AppLogLines>(const AppLogLines());

  static void add(String level, String message) {
    final line = LogLine(time: DateTime.now(), level: level, message: message);
    debugPrint(line.toString());
    final next = <LogLine>[...lines, line];
    DV.global<AppLogLines>(AppLogLines(next.length > capacity ? next.sublist(next.length - capacity) : next));
  }

  static void debug(String message) => add('debug', message);
  static void info(String message) => add('info', message);
  static void warning(String message) => add('warning', message);
  static void error(String message) => add('error', message);

  static void clear() => DV.global<AppLogLines>(const AppLogLines());
}

class const AppLogLines([final List<LogLine> lines = const <LogLine>[]]);
