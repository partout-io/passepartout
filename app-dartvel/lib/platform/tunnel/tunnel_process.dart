// SPDX-License-Identifier: GPL-3.0
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tunnel_protocol.dart';

class TunnelProcess {
  final String executable;
  final List<String> prefix;
  final Duration startTimeout;
  TunnelProcess(
    this.executable, {
    this.prefix = const [],
    this.startTimeout = const Duration(seconds: 90),
  });
  Process? _process;
  Future<void>? _finished;
  bool _starting = false;
  bool get isRunning => _process != null;
  Future<void> start(
    String profile,
    void Function(Map<String, dynamic>) event,
    void Function(String) log,
  ) async {
    if (_starting || _process != null) {
      throw StateError('Tunnel already running');
    }
    _starting = true;
    Directory? temp;
    final ready = Completer<void>();
    try {
      temp = await Directory.systemTemp.createTemp('partout-');
      await _chmod(temp.path, '700');
      final file = File('${temp.path}/profile.json');
      await file.writeAsString('');
      await _chmod(file.path, '600');
      await file.writeAsString(profile, flush: true);
      final process = await Process.start(executable, [...prefix, file.path]);
      _process = process;
      final outDone = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            try {
              final parsed = parseTunnelLine(line);
              if (parsed['type'] == 'ready' && !ready.isCompleted) {
                ready.complete();
              }
              if (parsed['type'] == 'error' && !ready.isCompleted) {
                ready.completeError(StateError(parsed['code'] as String));
              }
              event(parsed);
            } on FormatException {
              log('Invalid helper event');
            }
          })
          .asFuture<void>();
      final errDone = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(log)
          .asFuture<void>();
      _finished = () async {
        final code = await process.exitCode;
        await Future.wait([outDone, errDone]);
        if (!ready.isCompleted) {
          ready.completeError(
            StateError('Helper exited ($code) before startup'),
          );
        }
        log('Tunnel helper exited ($code)');
        event({'type': 'terminated', 'code': code});
        event({'type': 'status', 'status': 'disconnected'});
        if (identical(_process, process)) _process = null;
      }();
      await ready.future.timeout(startTimeout);
    } catch (_) {
      await stop();
      rethrow;
    } finally {
      _starting = false;
      if (temp != null && await temp.exists()) {
        await temp.delete(recursive: true);
      }
    }
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) return;
    try {
      process.stdin.writeln('stop');
      await process.stdin.flush();
    } catch (_) {}
    try {
      await _finished!.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      Process.killPid(process.pid, ProcessSignal.sigterm);
      try {
        await _finished!.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        throw StateError('Helper did not stop; privileged cleanup required');
      }
    }
  }
}

Future<void> _chmod(String path, String mode) async {
  final result = await Process.run('/bin/chmod', [mode, path]);
  if (result.exitCode != 0) {
    throw FileSystemException('Cannot secure tunnel file', path);
  }
}
