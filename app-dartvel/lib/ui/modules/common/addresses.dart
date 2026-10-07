// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Partout's `Address`, `Subnet` and `Route` string rules, in pure Dart so they
// run on every target (no dart:io on web). They follow
// PartoutCore/OpenAPI/Extensions/Core/{Address,Subnet,Route}+Extensions.swift.

/// `Address.Family`.
enum AddressFamily {
  v4,
  v6;

  /// Upstream `Address.Family.localizedDescription` (unlocalised).
  String get label => this == v4 ? 'IPv4' : 'IPv6';

  /// `Strings.Unlocalized.Placeholders.ipDestination(forFamily:)`.
  String get destinationPlaceholder => this == v4 ? '192.168.15.0/24' : 'fdbd:dcf8:d811:af73::/64';

  /// `Strings.Unlocalized.Placeholders.ipAddress(forFamily:)`.
  String get addressPlaceholder => this == v4 ? '192.168.15.1' : 'fdbd:dcf8:d811:af73::1';

  /// The IPModule key holding this family's IPSettings.
  String get moduleKey => this == v4 ? 'ipv4' : 'ipv6';
}

final RegExp _ipv4Part = RegExp(r'^\d{1,3}$');
final RegExp _ipv6Group = RegExp(r'^[0-9A-Fa-f]{1,4}$');

bool isIPv4(String text) {
  final parts = text.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (!_ipv4Part.hasMatch(part) || int.parse(part) > 255) return false;
  }
  return true;
}

/// IPv6 with optional `::` compression, an embedded IPv4 tail and a `%scope`.
bool isIPv6(String text) {
  var body = text;
  final scope = body.indexOf('%');
  if (scope >= 0) {
    if (scope == body.length - 1) return false;
    body = body.substring(0, scope);
  }
  final lastColon = body.lastIndexOf(':');
  if (lastColon < 0) return false;
  final tail = body.substring(lastColon + 1);
  if (tail.contains('.')) {
    if (!isIPv4(tail)) return false;
    body = '${body.substring(0, lastColon + 1)}0:0';
  }
  final halves = body.split('::');
  if (halves.length > 2) return false;
  List<String>? groupsOf(String half) {
    if (half.isEmpty) return <String>[];
    final groups = half.split(':');
    return groups.every(_ipv6Group.hasMatch) ? groups : null;
  }

  if (halves.length == 1) {
    final groups = groupsOf(halves[0]);
    return groups != null && groups.length == 8;
  }
  final left = groupsOf(halves[0]);
  final right = groupsOf(halves[1]);
  return left != null && right != null && left.length + right.length <= 7;
}

/// `Address(rawValue:)`: trimmed; null when empty. [family] is null for a hostname.
final class ParsedAddress {
  const ParsedAddress(this.rawValue, this.family);

  final String rawValue;
  final AddressFamily? family;

  bool get isIPAddress => family != null;

  static ParsedAddress? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (isIPv4(trimmed)) return ParsedAddress(trimmed, .v4);
    if (isIPv6(trimmed)) return ParsedAddress(trimmed, .v6);
    return ParsedAddress(trimmed, null);
  }
}

/// True when [text] is an IP address (what upstream calls `addr.isIPAddress`).
bool isIPAddress(String text) => ParsedAddress.parse(text)?.isIPAddress ?? false;

/// `Subnet(rawValue:)`: "addr" or "addr/prefix"; normalised to "addr/prefix".
final class ParsedSubnet {
  const ParsedSubnet(this.address, this.prefixLength);

  final ParsedAddress address;
  final int prefixLength;

  AddressFamily get family => address.family!;
  String get rawValue => '${address.rawValue}/$prefixLength';

  static ParsedSubnet? parse(String text) {
    final components = text.split('/');
    if (components.length > 2) return null;
    final address = ParsedAddress.parse(components[0]);
    if (address == null || !address.isIPAddress) return null;
    // The native subnet model does not support interface scopes.
    if (address.rawValue.contains('%')) return null;
    final maxPrefix = address.family == .v6 ? 128 : 32;
    int prefix = maxPrefix;
    if (components.length == 2) {
      final parsed = _swiftInt(components[1]);
      if (parsed == null) return null;
      prefix = parsed;
    }
    if (prefix < 0 || prefix > maxPrefix) return null;
    return ParsedSubnet(address, prefix);
  }
}

final RegExp _swiftIntPattern = RegExp(r'^[+-]?\d+$');

/// Swift's `Int(String)`: digits with an optional sign, no whitespace, no hex.
int? _swiftInt(String text) => _swiftIntPattern.hasMatch(text) ? int.tryParse(text) : null;

/// Public alias of Swift `Int(String)` for module editors (MTU, ports).
int? swiftInt(String text) => _swiftInt(text);

/// `Route.localizedDescription` (Partout+L10n.swift).
String routeDescription(Map<String, dynamic> route) {
  final destination = route['destination'] as String?;
  final gateway = route['gateway'] as String?;
  if (destination != null) {
    return gateway != null ? '$destination → $gateway' : destination;
  }
  if (gateway != null) return 'default → $gateway';
  return 'default → *';
}
