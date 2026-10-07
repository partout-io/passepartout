// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';

/// Lossless wire model for Profile in partout/scripts/openapi.yaml.
/// Keep unedited modules and optional fields intact, including private keys.
class const TunnelProfile({required final Map<String, dynamic> json}) {
  factory TunnelProfile.decode(String text) {
    final value = jsonDecode(text) as Map<String, dynamic>;
    if (value['id'] is! String || value['name'] is! String ||
        value['modules'] is! List || value['activeModulesIds'] is! List) {
      throw const FormatException('Invalid Partout profile');
    }
    return TunnelProfile(json: value);
  }
  String get id => json['id'] as String;
  String get name => json['name'] as String;
  List<TaggedModule> get modules => (json['modules'] as List)
      .map((value) => TaggedModule(json: Map<String, dynamic>.from(value as Map))).toList();
  String encode() => jsonEncode(json);
  TunnelProfile replaceModule(TaggedModule replacement) {
    final modules = this.modules;
    final index = modules.indexWhere((module) => module.id == replacement.id);
    if (index < 0) {
      modules.add(replacement);
    } else {
      modules[index] = replacement;
    }
    return TunnelProfile(json: {...json, 'modules': modules.map((m) => m.json).toList(),
      'activeModulesIds': {...(json['activeModulesIds'] as List).cast<String>(), replacement.id}.toList()});
  }
}

class const TaggedModule({required final Map<String, dynamic> json}) {
  String get type => json['type'] as String;
  Map<String, dynamic> get value => Map<String, dynamic>.from(json['value'] as Map);
  String get id => value['id'] as String;
}

/// Schema field names are exact; null values are omitted, never renamed.
class const DnsSettings({required final String id, required final Map<String, dynamic> protocolType,
  required final List<String> servers, final String? domainName,
  final List<String>? searchDomains, final bool? inheritsVPN,
  final String? domainPolicy, final bool? routesThroughVPN}) {
  TaggedModule toModule() => TaggedModule(json: {'type': 'DNS', 'value': {
    'id': id, 'protocolType': protocolType, 'servers': servers,
    if (domainName != null) 'domainName': domainName,
    if (searchDomains != null) 'searchDomains': searchDomains,
    if (inheritsVPN != null) 'inheritsVPN': inheritsVPN,
    if (domainPolicy != null) 'domainPolicy': domainPolicy,
    if (routesThroughVPN != null) 'routesThroughVPN': routesThroughVPN,
  }});
}

class const HttpProxySettings({required final String id, final String? proxy,
  final String? secureProxy, final String? pacURL, required final List<String> bypassDomains}) {
  TaggedModule toModule() => TaggedModule(json: {'type': 'HTTPProxy', 'value': {
    'id': id, if (proxy != null) 'proxy': proxy, if (secureProxy != null) 'secureProxy': secureProxy,
    if (pacURL != null) 'pacURL': pacURL, 'bypassDomains': bypassDomains,
  }});
}
