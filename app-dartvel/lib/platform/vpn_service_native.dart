// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../domain/profile.dart';
import 'generated/partout_bindings.dart';
import 'vpn_service.dart';

VpnService createVpnService() => PartoutVpnService();
class PartoutVpnService implements VpnService {
  @override
  bool get canConnect => false; // Set by the tunnel helper work (Linux first).
  @override
  String? get connectUnavailableReason => 'Connecting is not built yet on this platform.';
  late final PartoutBindings _abi;
  PartoutVpnService({String? libraryPath}) {
    final path = libraryPath ?? Platform.environment['PARTOUT_LIBRARY'] ??
      '../partout/bin/linux-x86_64/partout/lib/libpartout.so';
    _abi = PartoutBindings(DynamicLibrary.open(path));
    // Default logger excludes private data. No Dart callback on native threads.
    _abi.partout_init(nullptr);
  }
  Map<String, dynamic> _payload(String result) {
    final envelope = jsonDecode(result) as Map<String, dynamic>;
    if (envelope['payload'] is! Map) throw const FormatException('Partout rejected this configuration');
    return Map<String, dynamic>.from(envelope['payload'] as Map);
  }
  String _owned(Pointer<Char> result) {
    if (result == nullptr) throw const FormatException('Partout could not parse this configuration');
    try { return result.cast<Utf8>().toDartString(); }
    finally { malloc.free(result); }
  }
  String _call(String text, Pointer<Char> Function(Pointer<Char>) call) {
    final input = text.toNativeUtf8();
    try { return _owned(call(input.cast())); } finally { malloc.free(input); }
  }
  @override Future<TunnelProfile> importProfile(String text, String name) async {
    final input = text.toNativeUtf8(); final label = name.toNativeUtf8();
    try { return TunnelProfile.decode(jsonEncode(_payload(_owned(_abi.partout_import_profile(input.cast(), label.cast()))))); }
    finally { malloc.free(input); malloc.free(label); }
  }
  @override Future<TaggedModule> importModule(String text, {String? contextJson}) async {
    final input = text.toNativeUtf8(); final context = contextJson?.toNativeUtf8();
    try { return TaggedModule(json: _payload(_owned(_abi.partout_import_module(input.cast(), context?.cast() ?? nullptr)))); }
    finally { malloc.free(input); if (context != null) malloc.free(context); }
  }
  @override Future<String> exportModule(TaggedModule module) async => _call(jsonEncode(module.json), _abi.partout_export_module);
  @override Future<String> generateWireGuardKey() async => _owned(_abi.partout_wireguard_genkey());
  @override Future<String> wireGuardPublicKey(String privateKey) async => _call(privateKey, _abi.partout_wireguard_pubkey);
  @override Future<void> connect(TunnelProfile profile, {required void Function(TunnelEvent) onStatus}) async {
    throw UnsupportedError('Linux connection requires a CAP_NET_ADMIN helper and tun/route/DNS lifecycle. See docs/BUILD.md.');
  }
  @override Future<void> disconnect() async { _abi.partout_daemon_stop(); }
}
