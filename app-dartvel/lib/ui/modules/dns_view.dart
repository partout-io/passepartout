// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// DNS module editor: upstream DNSView.swift + DNSModule.Builder
// (PartoutCore DNSModule+Extensions.swift). Writes `DNSModule` of openapi.yaml.

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'common/addresses.dart';
import 'common/editable_list_section.dart';
import 'common/module_builder_cache.dart';
import 'module_view.dart';

/// `DNSProtocol`, in upstream's picker order.
const List<String> dnsProtocols = <String>['cleartext', 'https', 'tls'];

String dnsProtocolLabel(String protocol) => switch (protocol) {
      'https' => tr(Strings.entitiesDnsProtocolHttps),
      'tls' => tr(Strings.entitiesDnsProtocolTls),
      _ => tr(Strings.entitiesDnsProtocolCleartext),
    };

/// `DNSModule.Builder`.
final class DnsBuilder {
  DnsBuilder({
    this.protocolType = 'cleartext',
    List<ListItem<String>>? servers,
    this.dohURL = '',
    this.dotHostname = '',
    this.domains,
    this.inheritsVPN = false,
    this.domainPolicy,
    this.isFirstDomainPrimary = false,
    this.routesThroughVPN,
  }) : servers = servers ?? <ListItem<String>>[];

  /// `DNSModule.builder()`.
  factory DnsBuilder.fromJson(Map<String, dynamic> value) {
    final builder = DnsBuilder(servers: stringItems(value['servers'] as List?));
    final protocol = value['protocolType'];
    if (protocol is Map) {
      // Tagged `{"type": "https", "url": …}`, or legacy `{"https": {"url": …}}`.
      final type = protocol['type'] as String? ??
          (protocol.containsKey('https') ? 'https' : protocol.containsKey('tls') ? 'tls' : 'cleartext');
      if (type == 'https') {
        builder.protocolType = 'https';
        builder.dohURL = '${protocol['url'] ?? (protocol['https'] as Map?)?['url'] ?? ''}';
      } else if (type == 'tls') {
        builder.protocolType = 'tls';
        builder.dotHostname = '${protocol['hostname'] ?? (protocol['tls'] as Map?)?['hostname'] ?? ''}';
      }
    }
    final domainName = value['domainName'] as String?;
    final searchDomains = (value['searchDomains'] as List?)?.cast<String>();
    if (domainName != null) {
      builder.isFirstDomainPrimary = true;
      if (searchDomains != null) {
        builder.domains = stringItems(
            domainName == searchDomains.firstOrNull ? searchDomains : <String>[domainName, ...searchDomains]);
      } else {
        builder.domains = stringItems(<String>[domainName]);
      }
    } else if (searchDomains != null) {
      builder.isFirstDomainPrimary = false;
      builder.domains = stringItems(searchDomains);
    }
    builder.inheritsVPN = value['inheritsVPN'] == true;
    builder.domainPolicy = value['domainPolicy'] as String?;
    builder.routesThroughVPN = value['routesThroughVPN'] as bool?;
    return builder;
  }

  String protocolType;
  List<ListItem<String>> servers;
  String dohURL;
  String dotHostname;
  List<ListItem<String>>? domains;
  bool inheritsVPN;
  String? domainPolicy;
  bool isFirstDomainPrimary;
  bool? routesThroughVPN;

  List<String> get _validServers =>
      <String>[for (final item in servers) if (item.value.isNotEmpty && isIPAddress(item.value)) ParsedAddress.parse(item.value)!.rawValue];

  List<String>? get _validDomains => domains == null
      ? null
      : <String>[
          for (final item in domains!)
            if (ParsedAddress.parse(item.value) case final address? when !address.isIPAddress) address.rawValue,
        ];

  bool get _validDoH {
    final url = Uri.tryParse(dohURL);
    return dohURL.isNotEmpty && url != null && url.scheme == 'https';
  }

  /// What upstream's `build()` would refuse, as its error string key; null when valid.
  DVTranslationKey? get validationError {
    if (inheritsVPN) return null;
    for (final item in servers) {
      if (item.value.isNotEmpty && !isIPAddress(item.value)) return Strings.errorsModulesDNSNonIPServers;
    }
    for (final item in domains ?? const <ListItem<String>>[]) {
      if (item.value.isNotEmpty && (ParsedAddress.parse(item.value)?.isIPAddress ?? true)) {
        return Strings.errorsModulesDNSIpDomains;
      }
    }
    return switch (protocolType) {
      'https' => _validDoH ? null : Strings.errorsModulesDNSInvalidDoHURL,
      'tls' => dotHostname.isEmpty ? Strings.errorsModulesDNSEmptyDoTHostname : null,
      _ => _validServers.isEmpty ? Strings.errorsModulesDNSEmptyServers : null,
    };
  }

  /// The module fields `build()` produces from the valid parts. A protocol
  /// that cannot be built yet keeps its previous value; invalid entries are
  /// left out until fixed.
  Map<String, Object?> get changes {
    final validDomains = inheritsVPN ? null : _validDomains;
    final Object? protocol;
    if (inheritsVPN) {
      protocol = <String, dynamic>{'type': 'cleartext'};
    } else {
      protocol = switch (protocolType) {
        'https' => _validDoH ? <String, dynamic>{'type': 'https', 'url': dohURL} : _keep,
        'tls' => dotHostname.isNotEmpty ? <String, dynamic>{'type': 'tls', 'hostname': dotHostname} : _keep,
        _ => <String, dynamic>{'type': 'cleartext'},
      };
    }
    return <String, Object?>{
      if (protocol != _keep) 'protocolType': protocol,
      'servers': inheritsVPN ? <dynamic>[] : _validServers,
      'domainName': isFirstDomainPrimary ? validDomains?.firstOrNull : null,
      'searchDomains': validDomains,
      'inheritsVPN': inheritsVPN,
      'domainPolicy': domainPolicy,
      'routesThroughVPN': routesThroughVPN,
    };
  }

  static const Object _keep = Object();

  bool get canApplyDomainPolicy => inheritsVPN || protocolType == 'cleartext';

  bool get hasNonEmptyDomains => inheritsVPN || (domains?.any((item) => item.value.isNotEmpty) ?? false);
}

final ModuleBuilderCache<DnsBuilder> dnsBuilders = ModuleBuilderCache<DnsBuilder>(DnsBuilder.fromJson);

/// Upstream's save-time error for this DNS module, localised; null when valid.
String? dnsValidationError(TaggedModule module) {
  final key = dnsBuilders.resolve(module).validationError;
  return key == null ? null : tr(key);
}

/// DNS module sections.
List<Widget> dnsSections(BuildContext context, ModuleViewArgs args) {
  final builder = dnsBuilders.resolve(args.module);
  void edit(void Function(DnsBuilder) change) {
    change(builder);
    args.onChanged(dnsBuilders.write(args.module, builder, builder.changes));
  }

  return <Widget>[
    // inheritsSection
    PSSection(
      footer: tr(Strings.modulesDnsPolicyInheritsVpnFooter),
      children: <Widget>[
        PSToggleRow(
          title: tr(Strings.modulesDnsPolicyInheritsVpn),
          value: builder.inheritsVPN,
          onChanged: (value) => edit((b) => b.inheritsVPN = value),
        ),
      ],
    ),
    // behaviorSection: one container entry per row, each with its subtitle.
    PSSection(
      footer: tr(Strings.modulesDnsPolicyRouteThroughVpnFooter),
      children: <Widget>[
        PSPickerRow<bool?>(
          title: tr(Strings.modulesDnsPolicyRouteThroughVpn),
          value: builder.routesThroughVPN,
          options: const <bool?>[null, true, false],
          label: (option) => switch (option) {
            null => tr(Strings.globalNounsDefault),
            true => tr(Strings.globalNounsYes),
            false => tr(Strings.globalNounsNo),
          },
          onChanged: (value) => edit((b) => b.routesThroughVPN = value),
        ),
      ],
    ),
    PSSection(
      footer: tr(Strings.modulesDnsPolicyUseOnlyFooter),
      children: <Widget>[
        PSToggleRow(
          title: tr(Strings.modulesDnsPolicyUseOnly),
          value: builder.canApplyDomainPolicy && builder.domainPolicy == 'matchAndSearch',
          onChanged: builder.canApplyDomainPolicy
              ? (value) => edit((b) => b.domainPolicy = value ? 'matchAndSearch' : null)
              : null,
        ),
      ],
    ),
    if (!builder.inheritsVPN) ...<Widget>[
      PSSection(
        header: tr(Strings.modulesDnsCustomSettingsHeader),
        children: <Widget>[
          PSPickerRow<String>(
            title: tr(Strings.globalNounsProtocol),
            value: builder.protocolType,
            options: dnsProtocols,
            label: dnsProtocolLabel,
            onChanged: (value) => edit((b) => b.protocolType = value),
          ),
          if (builder.protocolType == 'https')
            PSTextRow(
              key: const ValueKey<String>('dns/dohURL'),
              label: 'URL',
              value: builder.dohURL,
              placeholder: 'https://1.2.3.4/some-query',
              keyboardType: TextInputType.url,
              onChanged: (value) => edit((b) => b.dohURL = value),
            ),
          if (builder.protocolType == 'tls')
            PSTextRow(
              key: const ValueKey<String>('dns/dotHostname'),
              label: tr(Strings.globalNounsHostname),
              value: builder.dotHostname,
              placeholder: 'dns-hostname.com',
              keyboardType: TextInputType.url,
              onChanged: (value) => edit((b) => b.dotHostname = value),
            ),
        ],
      ),
      EditableListSection<String>(
        key: const ValueKey<String>('dns/servers'),
        header: tr(Strings.entitiesDnsServers),
        addTitle: tr(Strings.modulesDnsServersAdd),
        items: builder.servers,
        emptyValue: () => '',
        isEmptyValue: (value) => value.isEmpty,
        onChanged: (items) => edit((b) => b.servers = items),
        itemBuilder: (context, item, setValue) => ListItemTextField(
          key: ValueKey<String>('dns/servers/${item.id}'),
          value: item.value,
          placeholder: '1.1.1.1',
          keyboardType: TextInputType.url,
          semanticLabel: tr(Strings.entitiesDnsServers),
          onChanged: setValue,
        ),
      ),
      if (builder.protocolType == 'cleartext') ...<Widget>[
        EditableListSection<String>(
          key: const ValueKey<String>('dns/domains'),
          header: tr(Strings.entitiesDnsDomains),
          addTitle: tr(Strings.modulesDnsDomainsAdd),
          items: builder.domains ?? <ListItem<String>>[],
          emptyValue: () => '',
          isEmptyValue: (value) => value.isEmpty,
          onChanged: (items) => edit((b) => b.domains = items),
          itemBuilder: (context, item, setValue) => ListItemTextField(
            key: ValueKey<String>('dns/domains/${item.id}'),
            value: item.value,
            placeholder: 'example.com',
            keyboardType: TextInputType.url,
            semanticLabel: tr(Strings.entitiesDnsDomains),
            onChanged: setValue,
          ),
        ),
        PSSection(
          footer: tr(Strings.modulesDnsDomainsFirstIsPrimaryFooter),
          children: <Widget>[
            PSToggleRow(
              title: tr(Strings.modulesDnsDomainsFirstIsPrimary),
              value: builder.isFirstDomainPrimary,
              onChanged: builder.hasNonEmptyDomains ? (value) => edit((b) => b.isFirstDomainPrimary = value) : null,
            ),
          ],
        ),
      ],
    ],
  ];
}
