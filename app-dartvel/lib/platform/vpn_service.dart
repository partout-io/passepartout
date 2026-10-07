// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import '../domain/profile.dart';
import 'vpn_service_stub.dart' if (dart.library.io) 'vpn_service_native.dart' as implementation;

/// App platform boundary, analogous to DV.Platform.*. Pages never import FFI.
abstract class VpnService {
  static VpnService? _instance;
  static VpnService get instance => _instance ??= implementation.createVpnService();
  TunnelProfile importProfile(String text, String name);
  TaggedModule importModule(String text, {String? contextJson});
  String exportModule(TaggedModule module);
  String generateWireGuardKey();
  String wireGuardPublicKey(String privateKey);
  Future<void> connect(TunnelProfile profile);
  Future<void> disconnect();
}
