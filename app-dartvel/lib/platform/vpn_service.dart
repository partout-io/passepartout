// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import '../domain/profile.dart';
import '../domain/tunnel_status.dart';
export '../domain/tunnel_status.dart';
import 'vpn_service_stub.dart' if (dart.library.io) 'vpn_service_native.dart' as implementation;

/// A change reported by the tunnel: Partout's `partout_daemon_events`
/// (`set_connection_status`, `set_data_count`, `set_last_error_code`).
class const TunnelEvent({final TunnelStatus? status, final int? received, final int? sent, final String? errorCode});

// Flutter-free on purpose: backend functions (server isolate) import this.

/// App platform boundary, analogous to DV.Platform.*. Pages never import FFI.
abstract class VpnService {
  static VpnService? _instance;
  static VpnService get instance => _instance ??= implementation.createVpnService();
  static set instance(VpnService service) => _instance = service;

  /// Where engine and tunnel log lines go. main.dart points it at AppLog;
  /// this file stays Flutter-free so backend functions can import it.
  static void Function(String level, String message) log = (_, _) {};

  /// Whether this target can bring a tunnel up at all (false on web).
  bool get canConnect;

  /// Why [canConnect] is false, in plain words; null when it is true.
  String? get connectUnavailableReason;

  // Engine calls are async: native targets call Partout through FFI, the web
  // target asks the app's own web-server binary (which links Partout).
  Future<TunnelProfile> importProfile(String text, String name);
  Future<TaggedModule> importModule(String text, {String? contextJson});
  Future<String> exportModule(TaggedModule module);
  Future<String> generateWireGuardKey();
  Future<String> wireGuardPublicKey(String privateKey);

  /// Brings [profile] up and reports progress through [onStatus] until it is down.
  Future<void> connect(TunnelProfile profile, {required void Function(TunnelEvent) onStatus});
  Future<void> disconnect();
}
