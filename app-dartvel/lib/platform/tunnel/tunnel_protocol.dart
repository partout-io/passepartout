// SPDX-License-Identifier: GPL-3.0
import 'dart:convert';

Map<String, dynamic> parseTunnelLine(String line) {
  final value = jsonDecode(line);
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected event object');
  }
  switch (value['type']) {
    case 'status':
      if (![
        'disconnected',
        'connecting',
        'connected',
        'disconnecting',
      ].contains(value['status'])) {
        throw const FormatException('Unknown status');
      }
    case 'data':
      for (final key in ['received', 'sent']) {
        if (value[key] is! int || (value[key] as int) < 0) {
          throw const FormatException('Invalid count');
        }
      }
    case 'error':
      if (value['code'] is! String) {
        throw const FormatException('Invalid error');
      }
    case 'log':
      if (value['message'] is! String) {
        throw const FormatException('Invalid log');
      }
    case 'ready':
      if (value['pid'] is! int || (value['pid'] as int) <= 0) {
        throw const FormatException('Invalid PID');
      }
    case 'exit':
      if (value['code'] is! int) throw const FormatException('Invalid exit');
    default:
      throw const FormatException('Unknown event');
  }
  return value;
}
