// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../domain/profile.dart';
import 'generated/partout_bindings.dart';
import 'vpn_service.dart';
import '../state/app_state.dart' show TunnelStatus;
import '../state/app_log.dart';
import 'tunnel/tunnel_process.dart';
import 'tunnel/tunnel_logs.dart';

VpnService createVpnService() => PartoutVpnService();

class PartoutVpnService implements VpnService {
  @override
  bool get canConnect => connectUnavailableReason == null;
  @override
  String? get connectUnavailableReason {
    if (!Platform.isLinux) {
      return 'Connecting is not built yet on this platform. See docs/TUNNEL.md.';
    }
    if (!_executable(_helper)) {
      return 'Install the Linux tunnel helper. See docs/TUNNEL.md.';
    }
    if (_pkexec == null) {
      return 'Install pkexec (polkit) to authorize the Linux tunnel helper.';
    }
    return null;
  }

  static bool _executable(String path) =>
      File(path).existsSync() && (FileStat.statSync(path).mode & 0x49) != 0;
  final String _helper;
  String? get _pkexec {
    for (final dir in (Platform.environment['PATH'] ?? '').split(':')) {
      if (dir.isNotEmpty && _executable('$dir/pkexec')) return '$dir/pkexec';
    }
    return null;
  }

  TunnelProcess? _tunnel;
  IOSink? _log;
  Future<void> _closeLog() async {
    final log = _log;
    _log = null;
    await log?.close();
  }

  void _writeLog(String text) {
    AppLog.info(text);
    _log?.writeln('${DateTime.now().toIso8601String()} $text');
  }

  late final PartoutBindings _abi;
  PartoutVpnService({String? libraryPath, String? helperPath})
    : _helper =
          helperPath ??
          Platform.environment['PARTOUT_TUNNEL_HELPER'] ??
          '/usr/local/libexec/passepartout/partout-tunnel' {
    final path =
        libraryPath ??
        Platform.environment['PARTOUT_LIBRARY'] ??
        '../partout/bin/linux-x86_64/partout/lib/libpartout.so';
    _abi = PartoutBindings(DynamicLibrary.open(path));
    // Default logger excludes private data. No Dart callback on native threads.
    _abi.partout_init(nullptr);
  }
  Map<String, dynamic> _payload(String result) {
    final envelope = jsonDecode(result) as Map<String, dynamic>;
    if (envelope['payload'] is! Map) {
      throw const FormatException('Partout rejected this configuration');
    }
    return Map<String, dynamic>.from(envelope['payload'] as Map);
  }

  String _owned(Pointer<Char> result) {
    if (result == nullptr) {
      throw const FormatException('Partout could not parse this configuration');
    }
    try {
      return result.cast<Utf8>().toDartString();
    } finally {
      malloc.free(result);
    }
  }

  String _call(String text, Pointer<Char> Function(Pointer<Char>) call) {
    final input = text.toNativeUtf8();
    try {
      return _owned(call(input.cast()));
    } finally {
      malloc.free(input);
    }
  }

  /// `partout_version()` returns a static string the library owns: not freed.
  @override
  Future<String> engineVersion() async {
    final version = _abi.partout_version();
    return version == nullptr ? 'Unknown' : version.cast<Utf8>().toDartString();
  }

  @override
  Future<TunnelProfile> importProfile(String text, String name) async {
    final input = text.toNativeUtf8();
    final label = name.toNativeUtf8();
    try {
      return TunnelProfile.decode(
        jsonEncode(
          _payload(
            _owned(_abi.partout_import_profile(input.cast(), label.cast())),
          ),
        ),
      );
    } finally {
      malloc.free(input);
      malloc.free(label);
    }
  }

  @override
  Future<TaggedModule> importModule(String text, {String? contextJson}) async {
    final input = text.toNativeUtf8();
    final context = contextJson?.toNativeUtf8();
    try {
      return TaggedModule(
        json: _payload(
          _owned(
            _abi.partout_import_module(
              input.cast(),
              context?.cast() ?? nullptr,
            ),
          ),
        ),
      );
    } finally {
      malloc.free(input);
      if (context != null) malloc.free(context);
    }
  }

  @override
  Future<String> exportModule(TaggedModule module) async =>
      _call(jsonEncode(module.json), _abi.partout_export_module);
  @override
  Future<String> generateWireGuardKey() async =>
      _owned(_abi.partout_wireguard_genkey());
  @override
  Future<String> wireGuardPublicKey(String privateKey) async =>
      _call(privateKey, _abi.partout_wireguard_pubkey);
  @override
  Future<void> connect(
    TunnelProfile profile, {
    required void Function(TunnelEvent) onStatus,
  }) async {
    if (!canConnect) throw UnsupportedError(connectUnavailableReason!);
    if (_tunnel != null) throw StateError('Tunnel already running');
    final dir = tunnelLogDirectory();
    await dir.create(recursive: true);
    final mode = await Process.run('/bin/chmod', ['700', dir.path]);
    if (mode.exitCode != 0) throw StateError('Cannot secure tunnel logs');
    final file = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.log',
    );
    await file.writeAsString('');
    final permissions = await Process.run('/bin/chmod', ['600', file.path]);
    if (permissions.exitCode != 0) throw StateError('Cannot secure tunnel log');
    _log = file.openWrite(mode: FileMode.append);
    final tunnel = TunnelProcess(_pkexec!, prefix: [_helper]);
    _tunnel = tunnel;
    onStatus(const TunnelEvent(status: TunnelStatus.connecting));
    try {
      await tunnel.start(profile.encode(), (event) {
        switch (event['type']) {
          case 'status':
            onStatus(
              TunnelEvent(
                status: TunnelStatus.values.byName(event['status'] as String),
              ),
            );
          case 'data':
            onStatus(
              TunnelEvent(
                received: event['received'] as int,
                sent: event['sent'] as int,
              ),
            );
          case 'error':
            onStatus(TunnelEvent(errorCode: event['code'] as String));
          case 'log':
            _writeLog(event['message'] as String);
          case 'terminated':
            if (identical(_tunnel, tunnel)) {
              _tunnel = null;
              _closeLog();
            }
        }
      }, _writeLog);
    } catch (_) {
      if (!tunnel.isRunning) {
        _tunnel = null;
        await _closeLog();
        onStatus(const TunnelEvent(status: TunnelStatus.disconnected));
      }
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final tunnel = _tunnel;
    if (tunnel == null) return;
    await tunnel.stop();
    _tunnel = null;
    await _closeLog();
  }
}
