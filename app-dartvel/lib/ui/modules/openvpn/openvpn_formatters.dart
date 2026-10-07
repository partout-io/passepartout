// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import '../../../l10n/strings.g.dart';
import '../../kit.dart';

/// Formats seconds as an OpenVPN time string: '0s', '10s', '1m', '1h1m1s'.
/// Upstream TimeInterval+Extensions.swift.
String formatTimeString(num? seconds) {
  if (seconds == null || seconds <= 0) {
    return tr(Strings.globalNounsDisabled);
  }
  var ticks = seconds.toInt();
  final hours = ticks ~/ 3600;
  ticks %= 3600;
  final minutes = ticks ~/ 60;
  final secs = ticks % 60;

  final comps = <String>[
    if (hours > 0) '${hours}h',
    if (minutes > 0) '${minutes}m',
    if (secs > 0) '${secs}s',
  ];
  return comps.isEmpty ? '0s' : comps.join();
}

/// Upstream `Int.localizedEntries`.
String? formatEntriesCount(int count) {
  if (count <= 0) return null;
  if (count == 1) return tr(Strings.globalNounsEntriesOne);
  return tr(Strings.globalNounsEntriesN, <Object>[count]);
}

/// Upstream `OpenVPN.TLSWrap.tlsWrapDescription`.
String formatTlsWrapStrategy(Map<String, dynamic>? tlsWrap) {
  if (tlsWrap == null) return tr(Strings.globalNounsDisabled);
  final strategy = tlsWrap['strategy'] as String?;
  return switch (strategy) {
    'auth' => '--tls-auth',
    'crypt' => '--tls-crypt',
    'crypt-v2' || 'cryptV2' => '--tls-crypt-v2',
    _ => tr(Strings.globalNounsDisabled),
  };
}

/// Upstream `OpenVPN.CompressionFraming.localizedDescription`.
String formatCompressionFraming(int? framing) => switch (framing) {
      1 => 'comp-lzo',
      2 || 3 => 'compress',
      _ => tr(Strings.globalNounsDisabled),
    };

/// Upstream `OpenVPN.CompressionAlgorithm.localizedDescription`.
String formatCompressionAlgorithm(int? algorithm) => switch (algorithm) {
      1 => 'LZO',
      2 => tr(Strings.entitiesOpenvpnCompressionAlgorithmOther),
      _ => tr(Strings.globalNounsDisabled),
    };

/// Formats boolean as Enabled / Disabled.
String formatEnabledDisabled(bool? value) =>
    (value == true) ? tr(Strings.globalNounsEnabled) : tr(Strings.globalNounsDisabled);

/// Upstream `OpenVPN.Credentials.OTPMethod.localizedDescription(style: .entity)`.
String formatOtpMethod(String? method) => switch (method?.toLowerCase()) {
      'append' => tr(Strings.entitiesOpenvpnOtpMethodAppend),
      'encode' => tr(Strings.entitiesOpenvpnOtpMethodEncode),
      _ => tr(Strings.entitiesOpenvpnOtpMethodNone),
    };

/// Upstream `OpenVPN.Credentials.OTPMethod.localizedDescription(style: .approachDescription)`.
String formatOtpApproach(String? method) => switch (method?.toLowerCase()) {
      'append' => tr(Strings.modulesOpenvpnCredentialsOtpMethodApproachAppend),
      'encode' => tr(Strings.modulesOpenvpnCredentialsOtpMethodApproachEncode),
      _ => '',
    };

/// Represents an editable remote endpoint from `configuration['remotes']`.
/// Upstream `ExtendedEndpoint` (rawValue: `address:proto:port`).
class ParsedRemote {
  const ParsedRemote({
    required this.address,
    required this.socketType,
    required this.port,
  });

  final String address;
  final String socketType;
  final int port;

  static const List<String> socketTypes = <String>[
    'UDP',
    'UDP4',
    'UDP6',
    'TCP',
    'TCP4',
    'TCP6',
  ];

  /// Parses `address:proto:port` or `address:port`.
  factory ParsedRemote.parse(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 3) {
      final portStr = parts.last;
      final proto = parts[parts.length - 2];
      final address = parts.sublist(0, parts.length - 2).join(':');
      final portNum = int.tryParse(portStr) ?? 1194;
      return ParsedRemote(
        address: address,
        socketType: proto.toUpperCase(),
        port: portNum,
      );
    } else if (parts.length == 2) {
      final portNum = int.tryParse(parts[1]) ?? 1194;
      return ParsedRemote(address: parts[0], socketType: 'UDP', port: portNum);
    }
    return ParsedRemote(address: raw, socketType: 'UDP', port: 1194);
  }

  String toRaw() => '$address:$socketType:$port';

  String displayLabel() => '$address:$port';

  ParsedRemote copyWith({String? address, String? socketType, int? port}) => ParsedRemote(
        address: address ?? this.address,
        socketType: socketType ?? this.socketType,
        port: port ?? this.port,
      );
}
