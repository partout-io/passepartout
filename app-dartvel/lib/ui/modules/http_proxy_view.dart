// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// HTTP proxy module editor: upstream HTTPProxyView.swift + HTTPProxyModule.Builder
// (PartoutCore HTTPProxyModule+Extensions.swift). Writes `HTTPProxyModule`.

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'common/addresses.dart';
import 'common/editable_list_section.dart';
import 'common/module_builder_cache.dart';
import 'module_view.dart';

/// `Endpoint(rawValue:)` split at the last colon: (address, port).
({String address, int port}) _splitEndpoint(String? endpoint) {
  if (endpoint == null) return (address: '', port: 0);
  final separator = endpoint.lastIndexOf(':');
  if (separator < 0) return (address: '', port: 0);
  final port = swiftInt(endpoint.substring(separator + 1));
  if (port == null || port < 0 || port > 65535) return (address: '', port: 0);
  return (address: endpoint.substring(0, separator), port: port);
}

/// `UInt16(text)` as `toString(omittingZero:)` reads it back: 0 when invalid.
int _port(String text) {
  final value = swiftInt(text);
  return value == null || value < 0 || value > 65535 ? 0 : value;
}

/// `HTTPProxyModule.Builder`. Ports are kept as typed.
final class HttpProxyBuilder {
  HttpProxyBuilder({
    this.address = '',
    this.port = '',
    this.secureAddress = '',
    this.securePort = '',
    this.pacURLString = '',
    List<ListItem<String>>? bypassDomains,
  }) : bypassDomains = bypassDomains ?? <ListItem<String>>[];

  /// `HTTPProxyModule.builder()`.
  factory HttpProxyBuilder.fromJson(Map<String, dynamic> value) {
    final proxy = _splitEndpoint(value['proxy'] as String?);
    final secure = _splitEndpoint(value['secureProxy'] as String?);
    return HttpProxyBuilder(
      address: proxy.address,
      port: proxy.port == 0 ? '' : '${proxy.port}',
      secureAddress: secure.address,
      securePort: secure.port == 0 ? '' : '${secure.port}',
      pacURLString: value['pacURL'] as String? ?? '',
      bypassDomains: stringItems(value['bypassDomains'] as List?),
    );
  }

  String address;
  String port;
  String secureAddress;
  String securePort;
  String pacURLString;
  List<ListItem<String>> bypassDomains;

  bool get _hasProxy => address.isNotEmpty && _port(port) > 0;
  bool get _hasSecureProxy => secureAddress.isNotEmpty && _port(securePort) > 0;

  /// What upstream's `build()` would refuse, as its error string key; null when valid.
  DVTranslationKey? get validationError {
    if (_hasProxy && !isIPAddress(address)) return Strings.errorsModulesHTTPProxyAddress;
    if (_hasSecureProxy && !isIPAddress(secureAddress)) return Strings.errorsModulesHTTPProxySecureAddress;
    if (pacURLString.isNotEmpty && Uri.tryParse(pacURLString) == null) return Strings.errorsModulesHTTPProxyPacURLString;
    for (final item in bypassDomains) {
      final address = ParsedAddress.parse(item.value);
      if (address == null || address.isIPAddress) return Strings.errorsModulesHTTPProxyBypassDomains;
    }
    return null;
  }

  /// The fields `build()` produces from the valid parts; invalid ones are
  /// left out until fixed.
  Map<String, Object?> get changes => <String, Object?>{
        'proxy': _hasProxy && isIPAddress(address) ? '${ParsedAddress.parse(address)!.rawValue}:${_port(port)}' : null,
        'secureProxy': _hasSecureProxy && isIPAddress(secureAddress)
            ? '${ParsedAddress.parse(secureAddress)!.rawValue}:${_port(securePort)}'
            : null,
        'pacURL': pacURLString.isNotEmpty && Uri.tryParse(pacURLString) != null ? pacURLString : null,
        'bypassDomains': <String>[
          for (final item in bypassDomains)
            if (ParsedAddress.parse(item.value) case final address? when !address.isIPAddress) address.rawValue,
        ],
      };
}

final ModuleBuilderCache<HttpProxyBuilder> httpProxyBuilders =
    ModuleBuilderCache<HttpProxyBuilder>(HttpProxyBuilder.fromJson);

/// Upstream's save-time error for this HTTP proxy module, localised; null when valid.
String? httpProxyValidationError(TaggedModule module) {
  final key = httpProxyBuilders.resolve(module).validationError;
  return key == null ? null : tr(key);
}

/// HTTP Proxy module sections.
List<Widget> httpProxySections(BuildContext context, ModuleViewArgs args) {
  final builder = httpProxyBuilders.resolve(args.module);
  void edit(void Function(HttpProxyBuilder) change) {
    change(builder);
    args.onChanged(httpProxyBuilders.write(args.module, builder, builder.changes));
  }

  Widget endpointSection(String header, String keyPrefix, String address, String port,
          ValueChanged<String> onAddress, ValueChanged<String> onPort) =>
      PSSection(
        header: header,
        children: <Widget>[
          PSTextRow(
            key: ValueKey<String>('$keyPrefix/address'),
            label: tr(Strings.globalNounsAddress),
            value: address,
            placeholder: AddressFamily.v4.addressPlaceholder,
            keyboardType: TextInputType.url,
            onChanged: onAddress,
          ),
          PSTextRow(
            key: ValueKey<String>('$keyPrefix/port'),
            label: tr(Strings.globalNounsPort),
            value: port,
            placeholder: '1080',
            keyboardType: TextInputType.number,
            onChanged: onPort,
          ),
        ],
      );

  return <Widget>[
    endpointSection('HTTP', 'proxy/http', builder.address, builder.port,
        (value) => edit((b) => b.address = value), (value) => edit((b) => b.port = value)),
    endpointSection('HTTPS', 'proxy/https', builder.secureAddress, builder.securePort,
        (value) => edit((b) => b.secureAddress = value), (value) => edit((b) => b.securePort = value)),
    PSSection(
      header: 'PAC',
      children: <Widget>[
        PSTextRow(
          key: const ValueKey<String>('proxy/pac'),
          label: 'URL',
          value: builder.pacURLString,
          placeholder: 'http://proxy.com/pac.url',
          keyboardType: TextInputType.url,
          onChanged: (value) => edit((b) => b.pacURLString = value),
        ),
      ],
    ),
    EditableListSection<String>(
      key: const ValueKey<String>('proxy/bypass'),
      header: tr(Strings.entitiesHttpProxyBypassDomains),
      addTitle: tr(Strings.modulesHttpProxyBypassDomainsAdd),
      items: builder.bypassDomains,
      emptyValue: () => '',
      isEmptyValue: (value) => value.isEmpty,
      onChanged: (items) => edit((b) => b.bypassDomains = items),
      itemBuilder: (context, item, setValue) => ListItemTextField(
        key: ValueKey<String>('proxy/bypass/${item.id}'),
        value: item.value,
        placeholder: 'example.com',
        keyboardType: TextInputType.url,
        semanticLabel: tr(Strings.entitiesHttpProxyBypassDomains),
        onChanged: setValue,
      ),
    ),
  ];
}
