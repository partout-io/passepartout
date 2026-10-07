// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import '../dartvel_client/dartvel_client.dart';
import '../domain/profile.dart';
import 'vpn_service.dart';



/// Installed by main.dart on web. The browser has no tunnel API. Parsing goes through the app's own
/// web-server binary, which links Partout; connecting is unavailable.
class const WebVpnService() implements VpnService {
  @override
  bool get canConnect => false;
  @override
  String? get connectUnavailableReason => 'A browser cannot open a VPN tunnel. Use the desktop or mobile app to connect.';

  @override
  Future<TunnelProfile> importProfile(String text, String name) async =>
      TunnelProfile.decode(await importProfileText(text: text, name: name));
  @override
  Future<TaggedModule> importModule(String text, {String? contextJson}) => throw UnsupportedError(connectUnavailableReason!);
  @override
  Future<String> exportModule(TaggedModule module) => throw UnsupportedError(connectUnavailableReason!);
  @override
  Future<String> generateWireGuardKey() => throw UnsupportedError(connectUnavailableReason!);
  @override
  Future<String> wireGuardPublicKey(String privateKey) => throw UnsupportedError(connectUnavailableReason!);
  @override
  Future<void> connect(TunnelProfile profile, {required void Function(TunnelEvent) onStatus}) =>
      throw UnsupportedError(connectUnavailableReason!);
  @override
  Future<void> disconnect() async {}
  /// The engine runs in the web-server binary, which has no version endpoint yet.
  @override
  Future<String> engineVersion() async => 'Not available in the browser';
}
