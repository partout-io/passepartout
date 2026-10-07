// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import '../domain/profile.dart';
import 'vpn_service.dart';
VpnService createVpnService() => const UnavailableVpnService();
class const UnavailableVpnService() implements VpnService {
  Never _unsupported() => throw UnsupportedError('Use the Linux web-server for profile import. Browser VPN connections are unavailable.');
  @override TunnelProfile importProfile(String text, String name) => _unsupported();
  @override TaggedModule importModule(String text, {String? contextJson}) => _unsupported();
  @override String exportModule(TaggedModule module) => _unsupported();
  @override String generateWireGuardKey() => _unsupported();
  @override String wireGuardPublicKey(String privateKey) => _unsupported();
  @override Future<void> connect(TunnelProfile profile) async => _unsupported();
  @override Future<void> disconnect() async => _unsupported();
}
