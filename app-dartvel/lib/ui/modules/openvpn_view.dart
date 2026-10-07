// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'module_view.dart';
import 'openvpn/openvpn_credentials_screen.dart';
import 'openvpn/openvpn_formatters.dart';
import 'openvpn/openvpn_import_dialog.dart';
import 'openvpn/openvpn_remotes_screen.dart';

/// OpenVPN module sections.
/// Matches upstream `OpenVPNView` and `OpenVPNView+Configuration.swift`.
List<Widget> openVPNSections(BuildContext context, ModuleViewArgs args) {
  final rawConfig = args.module.value['configuration'];
  final Map<String, dynamic>? config =
      rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : null;

  if (config == null || config.isEmpty) {
    return <Widget>[
      PSSection(
        children: <Widget>[
          PSRow(
            title: tr(Strings.modulesGeneralRowsImportFromFile),
            leading: const Icon(Icons.file_upload_outlined),
            onTap: () => showOpenVPNImportDialog(
              context,
              onImported: args.onChanged,
              currentModule: args.module,
            ),
          ),
        ],
      ),
    ];
  }

  final sections = <Widget>[];

  // 1. Import section (to allow re-importing / updating configuration)
  sections.add(
    PSSection(
      children: <Widget>[
        PSRow(
          title: tr(Strings.modulesGeneralRowsImportFromFile),
          leading: const Icon(Icons.file_upload_outlined),
          onTap: () => showOpenVPNImportDialog(
            context,
            onImported: args.onChanged,
            currentModule: args.module,
          ),
        ),
      ],
    ),
  );

  // 2. Connection section
  final remotes = config['remotes'] as List?;
  if (remotes != null) {
    sections.add(
      PSSection(
        header: tr(Strings.globalNounsConnection),
        children: <Widget>[
          PSRow(
            title: tr(Strings.modulesOpenvpnRemotes),
            value: formatEntriesCount(remotes.length),
            navigates: true,
            onTap: () => pushModuleSection(args, 'remotes'),
          ),
        ],
      ),
    );
  }

  // 3. Account section
  if (config['authUserPass'] == true) {
    sections.add(
      PSSection(
        header: tr(Strings.globalNounsAccount),
        children: <Widget>[
          PSRow(
            title: tr(Strings.modulesOpenvpnCredentials),
            navigates: true,
            onTap: () => pushModuleSection(args, 'credentials'),
          ),
        ],
      ),
    );
  }

  // 4. Pull section
  final rawPull = config['pullMask'] ?? config['noPullMask'];
  final pullMask = rawPull is List ? rawPull.map((e) => e.toString()).toList() : null;
  if (pullMask != null && pullMask.isNotEmpty) {
    final pullRows = <Widget>[];
    for (final item in pullMask) {
      final label = switch (item.toLowerCase()) {
        'routes' => tr(Strings.globalNounsRoutes),
        'dns' => 'DNS',
        'proxy' => 'Proxy',
        _ => item,
      };
      pullRows.add(PSRow(title: label));
    }
    sections.add(
      PSSection(
        header: tr(Strings.modulesOpenvpnPull),
        children: pullRows,
      ),
    );
  }

  // 5. Redirect Gateway section
  final rawPolicies = config['routingPolicies'];
  final routingPolicies = rawPolicies is List ? rawPolicies.map((e) => e.toString()).toList() : null;
  if (routingPolicies != null && routingPolicies.isNotEmpty) {
    final policyRows = <Widget>[];
    for (final policy in routingPolicies) {
      final label = switch (policy) {
        'IPv4' => 'IPv4',
        'IPv6' => 'IPv6',
        'blockLocal' => 'Block local LAN',
        _ => policy,
      };
      policyRows.add(PSRow(title: label));
    }
    sections.add(
      PSSection(
        header: tr(Strings.modulesOpenvpnRedirectGateway),
        children: policyRows,
      ),
    );
  }

  // 6. IPv4 section
  final ipv4 = config['ipv4'] is Map ? Map<String, dynamic>.from(config['ipv4'] as Map) : null;
  final routes4 = config['routes4'] as List?;
  final ipv4Rows = _buildIpRows(context, ipv4, routes4);
  if (ipv4Rows.isNotEmpty) {
    sections.add(
      PSSection(
        header: 'IPv4',
        children: ipv4Rows,
      ),
    );
  }

  // 7. IPv6 section
  final ipv6 = config['ipv6'] is Map ? Map<String, dynamic>.from(config['ipv6'] as Map) : null;
  final routes6 = config['routes6'] as List?;
  final ipv6Rows = _buildIpRows(context, ipv6, routes6);
  if (ipv6Rows.isNotEmpty) {
    sections.add(
      PSSection(
        header: 'IPv6',
        children: ipv6Rows,
      ),
    );
  }

  // 8. DNS section
  final dnsServers = config['dnsServers'] as List?;
  final dnsDomain = config['dnsDomain'] as String?;
  final searchDomains = config['searchDomains'] as List?;
  final dnsRows = <Widget>[
    if (dnsServers != null && dnsServers.isNotEmpty)
      PSRow(
        title: tr(Strings.globalNounsServers),
        value: dnsServers.join(', '),
        selectable: true,
      ),
    if (dnsDomain != null && dnsDomain.isNotEmpty)
      PSRow(
        title: tr(Strings.globalNounsDomain),
        value: dnsDomain,
        selectable: true,
      ),
    if (searchDomains != null && searchDomains.isNotEmpty)
      PSRow(
        title: tr(Strings.entitiesDnsSearchDomains),
        value: searchDomains.join(', '),
        selectable: true,
      ),
  ];
  if (dnsRows.isNotEmpty) {
    sections.add(
      PSSection(
        header: 'DNS',
        children: dnsRows,
      ),
    );
  }

  // 9. Proxy section
  final httpProxy = config['httpProxy'];
  final httpsProxy = config['httpsProxy'];
  final pacUrl = config['proxyAutoConfigurationURL'] as String?;
  final proxyBypass = config['proxyBypassDomains'] as List?;
  final proxyRows = <Widget>[
    if (httpProxy != null)
      PSRow(
        title: 'HTTP',
        value: httpProxy.toString(),
        selectable: true,
      ),
    if (httpsProxy != null)
      PSRow(
        title: 'HTTPS',
        value: httpsProxy.toString(),
        selectable: true,
      ),
    if (pacUrl != null && pacUrl.isNotEmpty)
      PSRow(
        title: 'PAC',
        value: pacUrl,
        selectable: true,
      ),
    if (proxyBypass != null && proxyBypass.isNotEmpty)
      PSRow(
        title: tr(Strings.entitiesHttpProxyBypassDomains),
        value: proxyBypass.join(', '),
        selectable: true,
      ),
  ];
  if (proxyRows.isNotEmpty) {
    sections.add(
      PSSection(
        header: 'Proxy',
        children: proxyRows,
      ),
    );
  }

  // 10. Communication section
  final dataCiphers = config['dataCiphers'] as List?;
  final cipher = config['cipher'] as String?;
  final digest = config['digest'] as String?;
  final xorMethod = config['xorMethod'] is Map
      ? Map<String, dynamic>.from(config['xorMethod'] as Map)
      : null;

  final commRows = <Widget>[
    if (dataCiphers != null && dataCiphers.isNotEmpty)
      PSRow(
        title: tr(Strings.modulesOpenvpnDataCiphers),
        value: dataCiphers.join(':'),
        navigates: true,
        onTap: () => pushModuleSection(args, 'data-ciphers'),
      ),
    if (cipher != null && cipher.isNotEmpty)
      PSRow(
        title: tr(Strings.modulesOpenvpnCipher),
        value: cipher,
      ),
    if (digest != null && digest.isNotEmpty)
      PSRow(
        title: tr(Strings.modulesOpenvpnDigest),
        value: digest,
      ),
    if (xorMethod != null)
      PSRow(
        title: 'XOR',
        value: xorMethod['type']?.toString(),
        navigates: true,
        onTap: () => pushModuleSection(args, 'xor'),
      ),
  ];
  if (commRows.isNotEmpty) {
    sections.add(
      PSSection(
        header: tr(Strings.modulesOpenvpnCommunication),
        children: commRows,
      ),
    );
  }

  // 11. Compression section
  final compressionFraming = config['compressionFraming'] as int?;
  final compressionAlgorithm = config['compressionAlgorithm'] as int?;
  if (compressionFraming != null || compressionAlgorithm != null) {
    sections.add(
      PSSection(
        header: tr(Strings.modulesOpenvpnCompression),
        children: <Widget>[
          if (compressionFraming != null)
            PSRow(
              title: tr(Strings.modulesOpenvpnCompressionFraming),
              value: formatCompressionFraming(compressionFraming),
            ),
          if (compressionAlgorithm != null)
            PSRow(
              title: tr(Strings.modulesOpenvpnCompressionAlgorithm),
              value: formatCompressionAlgorithm(compressionAlgorithm),
            ),
        ],
      ),
    );
  }

  // 12. TLS section
  final ca = config['ca'] as String?;
  final clientCert = config['clientCertificate'] as String?;
  final clientKey = config['clientKey'] as String?;
  final tlsWrap = config['tlsWrap'] is Map
      ? Map<String, dynamic>.from(config['tlsWrap'] as Map)
      : null;
  final checksEKU = config['checksEKU'] as bool?;

  final tlsRows = <Widget>[
    if (ca != null && ca.isNotEmpty)
      PSRow(
        title: 'CA',
        value: 'PEM',
        navigates: true,
        onTap: () => pushModuleSection(args, 'ca'),
      ),
    if (clientCert != null && clientCert.isNotEmpty)
      PSRow(
        title: tr(Strings.globalNounsCertificate),
        value: 'PEM',
        navigates: true,
        onTap: () => pushModuleSection(args, 'certificate'),
      ),
    if (clientKey != null && clientKey.isNotEmpty)
      PSRow(
        title: tr(Strings.globalNounsKey),
        value: 'PEM',
        navigates: true,
        onTap: () => pushModuleSection(args, 'key'),
      ),
    if (tlsWrap != null)
      PSRow(
        title: tr(Strings.modulesOpenvpnTlsWrap),
        value: formatTlsWrapStrategy(tlsWrap),
        navigates: true,
        onTap: () => pushModuleSection(args, 'tls-wrap'),
      ),
    if (checksEKU != null)
      PSRow(
        title: tr(Strings.modulesOpenvpnEku),
        value: formatEnabledDisabled(checksEKU),
      ),
  ];
  if (tlsRows.isNotEmpty) {
    sections.add(
      PSSection(
        header: 'TLS',
        children: tlsRows,
      ),
    );
  }

  // 13. Keep-alive section
  final keepAliveInterval = config['keepAliveInterval'] as num?;
  final keepAliveTimeout = config['keepAliveTimeout'] as num?;
  if (keepAliveInterval != null || keepAliveTimeout != null) {
    sections.add(
      PSSection(
        header: tr(Strings.globalNounsKeepAlive),
        children: <Widget>[
          if (keepAliveInterval != null)
            PSRow(
              title: tr(Strings.globalNounsInterval),
              value: formatTimeString(keepAliveInterval),
            ),
          if (keepAliveTimeout != null)
            PSRow(
              title: tr(Strings.globalNounsTimeout),
              value: formatTimeString(keepAliveTimeout),
            ),
        ],
      ),
    );
  }

  // 14. Other section
  final renegotiatesAfter = config['renegotiatesAfter'] as num?;
  final randomizeEndpoint = config['randomizeEndpoint'] as bool?;
  final randomizeHostnames = config['randomizeHostnames'] as bool?;

  final otherRows = <Widget>[
    if (renegotiatesAfter != null)
      PSRow(
        title: tr(Strings.modulesOpenvpnRenegotiation),
        value: formatTimeString(renegotiatesAfter),
      ),
    if (randomizeEndpoint != null)
      PSRow(
        title: tr(Strings.modulesOpenvpnRandomizeEndpoint),
        value: formatEnabledDisabled(randomizeEndpoint),
      ),
    if (randomizeHostnames != null)
      PSRow(
        title: tr(Strings.modulesOpenvpnRandomizeHostname),
        value: formatEnabledDisabled(randomizeHostnames),
      ),
  ];
  if (otherRows.isNotEmpty) {
    sections.add(
      PSSection(
        header: tr(Strings.globalNounsOther),
        children: otherRows,
      ),
    );
  }

  return sections;
}

/// OpenVPN sub-pages, at `/profiles/<id>/modules/<moduleId>/<section>`:
/// `remotes`, `credentials`, and the read-only `data-ciphers`, `xor`, `ca`,
/// `certificate`, `key` and `tls-wrap` content.
Widget? openVPNSubpage(BuildContext context, ModuleViewArgs args, String section) {
  final rawConfig = args.module.value['configuration'];
  final config = rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : <String, dynamic>{};
  Widget? content(String title, Object? text) =>
      text is String && text.isNotEmpty ? PSLongContentPage(title: title, text: text) : null;
  switch (section) {
    case 'remotes':
      return OpenVPNRemotesScreen(module: args.module, onChanged: args.onChanged);
    case 'credentials':
      return OpenVPNCredentialsScreen(module: args.module, onChanged: args.onChanged);
    case 'data-ciphers':
      final dataCiphers = config['dataCiphers'];
      return dataCiphers is List && dataCiphers.isNotEmpty
          ? content(tr(Strings.modulesOpenvpnDataCiphers), dataCiphers.join('\n'))
          : null;
    case 'xor':
      final xorMethod = config['xorMethod'];
      if (xorMethod is! Map) return null;
      final type = xorMethod['type']?.toString() ?? 'XOR';
      final mask = xorMethod['mask']?.toString() ?? '';
      return content('XOR', mask.isNotEmpty ? '$type\n\nMask: $mask' : type);
    case 'ca':
      return content('CA', config['ca']);
    case 'certificate':
      return content(tr(Strings.globalNounsCertificate), config['clientCertificate']);
    case 'key':
      return content(tr(Strings.globalNounsKey), config['clientKey']);
    case 'tls-wrap':
      final tlsWrap = config['tlsWrap'];
      if (tlsWrap is! Map) return null;
      final wrap = Map<String, dynamic>.from(tlsWrap);
      final keyData = wrap['key'] is Map ? (wrap['key'] as Map)['data']?.toString() ?? '' : '';
      return content(tr(Strings.modulesOpenvpnTlsWrap), 'Strategy: ${formatTlsWrapStrategy(wrap)}\nKey: $keyData');
  }
  return null;
}

List<Widget> _buildIpRows(
  BuildContext context,
  Map<String, dynamic>? ip,
  List<dynamic>? extraRoutes,
) {
  if (ip == null && (extraRoutes == null || extraRoutes.isEmpty)) {
    return <Widget>[];
  }
  final rows = <Widget>[];

  final subnets = ip?['subnets'] as List?;
  final address = ip?['address']?.toString() ??
      (subnets != null && subnets.isNotEmpty ? subnets.first.toString() : null);
  if (address != null && address.isNotEmpty) {
    rows.add(
      PSRow(
        title: tr(Strings.globalNounsAddress),
        value: address,
        selectable: true,
      ),
    );
  }

  final gateway = ip?['defaultGateway']?.toString();
  if (gateway != null && gateway.isNotEmpty) {
    rows.add(
      PSRow(
        title: tr(Strings.globalNounsGateway),
        value: gateway,
        selectable: true,
      ),
    );
  }

  final incRoutes = <dynamic>[
    ...?ip?['includedRoutes'] as List?,
    ...?extraRoutes,
  ];
  if (incRoutes.isNotEmpty) {
    rows.add(
      PSRow(
        title: tr(Strings.modulesIpRoutesIncluded),
        value: formatEntriesCount(incRoutes.length),
      ),
    );
  }

  final excRoutes = ip?['excludedRoutes'] as List?;
  if (excRoutes != null && excRoutes.isNotEmpty) {
    rows.add(
      PSRow(
        title: tr(Strings.modulesIpRoutesExcluded),
        value: formatEntriesCount(excRoutes.length),
      ),
    );
  }

  return rows;
}
