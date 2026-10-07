// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
// Targets without dart:io. main.dart replaces it with WebVpnService on web;
// it stays Flutter-free so backend code can import vpn_service.dart.
import '../domain/profile.dart';
import 'vpn_service.dart';

VpnService createVpnService() => const UnavailableVpnService();

class const UnavailableVpnService() implements VpnService {
  static const String _reason = 'The VPN engine is not available on this target.';
  Never _unavailable() => throw UnsupportedError(_reason);
  @override
  bool get canConnect => false;
  @override
  String? get connectUnavailableReason => _reason;
  @override
  Future<TunnelProfile> importProfile(String text, String name) async => _unavailable();
  @override
  Future<TaggedModule> importModule(String text, {String? contextJson}) async => _unavailable();
  @override
  Future<String> exportModule(TaggedModule module) async => _unavailable();
  @override
  Future<String> generateWireGuardKey() async => _unavailable();
  @override
  Future<String> wireGuardPublicKey(String privateKey) async => _unavailable();
  @override
  Future<void> connect(TunnelProfile profile, {required void Function(TunnelEvent) onStatus}) async => _unavailable();
  @override
  Future<void> disconnect() async {}
}
