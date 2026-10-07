// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// IP module editor: upstream IPView.swift, IPView+Route.swift and
// IPModule.Builder (PartoutCore IPModule+Extensions.swift). Writes `IPModule`
// with `IPSettings`, `Route` and `Subnet` of openapi.yaml.

import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'common/addresses.dart';
import 'common/module_builder_cache.dart';
import 'module_view.dart';

/// `IPSettings` as JSON, always with its three required lists.
Map<String, dynamic> _settings(Object? json) {
  final value = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
  return <String, dynamic>{
    ...value,
    'subnets': <dynamic>[...?(value['subnets'] as List?)],
    'includedRoutes': <dynamic>[...?(value['includedRoutes'] as List?)],
    'excludedRoutes': <dynamic>[...?(value['excludedRoutes'] as List?)],
  };
}

/// `IPSettings.nilIfEmpty`.
Map<String, dynamic>? _nilIfEmpty(Map<String, dynamic>? settings) {
  if (settings == null) return null;
  final empty = (settings['subnets'] as List).isEmpty &&
      (settings['includedRoutes'] as List).isEmpty &&
      (settings['excludedRoutes'] as List).isEmpty;
  return empty ? null : settings;
}

/// `IPModule.Builder`, plus IPView's `subnets` text state and the MTU text.
final class IpBuilder {
  IpBuilder({this.ipv4, this.ipv6, this.mtu = ''});

  factory IpBuilder.fromJson(Map<String, dynamic> value) {
    final builder = IpBuilder(
      ipv4: value['ipv4'] == null ? null : _settings(value['ipv4']),
      ipv6: value['ipv6'] == null ? null : _settings(value['ipv6']),
      mtu: value['mtu'] == null ? '' : '${value['mtu']}',
    );
    // IPView.loadSubnets(): the first subnet of each family.
    for (final family in AddressFamily.values) {
      final subnets = builder.settings(family)?['subnets'] as List?;
      if (subnets != null && subnets.isNotEmpty) builder.subnetText[family] = '${subnets.first}';
    }
    return builder;
  }

  Map<String, dynamic>? ipv4;
  Map<String, dynamic>? ipv6;
  String mtu;
  final Map<AddressFamily, String> subnetText = <AddressFamily, String>{};

  Map<String, dynamic>? settings(AddressFamily family) => family == .v4 ? ipv4 : ipv6;

  void _setSettings(AddressFamily family, Map<String, dynamic>? value) {
    if (family == .v4) {
      ipv4 = value;
    } else {
      ipv6 = value;
    }
  }

  /// IPView.saveSubnets(): `ipvX?.with(subnet:) ?? IPSettings(subnet:)`.
  void setSubnet(AddressFamily family, String text) {
    subnetText[family] = text;
    final subnet = ParsedSubnet.parse(text);
    final next = _settings(settings(family));
    next['subnets'] = <dynamic>[?subnet?.rawValue];
    _setSettings(family, next);
  }

  /// `IPSettings.include(_:)` / `exclude(_:)`, creating the settings if missing.
  void addRoute(AddressFamily family, Map<String, dynamic> route, {required bool included}) {
    final next = _settings(settings(family));
    final key = included ? 'includedRoutes' : 'excludedRoutes';
    next[key] = <dynamic>[...next[key] as List, route];
    _setSettings(family, next);
  }

  /// `removeIncluded(at:)` / `removeExcluded(at:)`.
  void removeRoute(AddressFamily family, int index, {required bool included}) {
    final next = _settings(settings(family));
    final key = included ? 'includedRoutes' : 'excludedRoutes';
    next[key] = <dynamic>[...next[key] as List]..removeAt(index);
    _setSettings(family, next);
  }

  /// `build()`: empty settings are omitted; an MTU that is not a number is omitted.
  Map<String, Object?> get changes => <String, Object?>{
        'ipv4': _nilIfEmpty(ipv4),
        'ipv6': _nilIfEmpty(ipv6),
        'mtu': swiftInt(mtu),
      };
}

final ModuleBuilderCache<IpBuilder> ipBuilders = ModuleBuilderCache<IpBuilder>(IpBuilder.fromJson);

/// RouteView.parseAndSubmit(): the route JSON, or null when upstream would
/// ignore the OK (destination not a subnet of [family], gateway of another family).
Map<String, dynamic>? parseRoute(AddressFamily family,
    {required bool isDefault, required String destination, required String gateway}) {
  if (isDefault) return <String, dynamic>{};
  final subnet = ParsedSubnet.parse(destination);
  if (subnet == null) return null;
  final gatewayAddress = ParsedAddress.parse(gateway);
  if (subnet.family != family) return null;
  if (gatewayAddress != null && gatewayAddress.family != family) return null;
  return <String, dynamic>{
    'destination': subnet.rawValue,
    'gateway': ?gatewayAddress?.rawValue,
  };
}

/// IP module sections.
List<Widget> ipSections(BuildContext context, ModuleViewArgs args) {
  final builder = ipBuilders.resolve(args.module);
  void edit(void Function(IpBuilder) change) {
    change(builder);
    args.onChanged(ipBuilders.write(args.module, builder, builder.changes));
  }

  Future<void> presentRoute(AddressFamily family, {required bool included}) async {
    final route = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RouteDialog(
        family: family,
        title: tr(included ? Strings.modulesIpRoutesInclude : Strings.modulesIpRoutesExclude),
      ),
    );
    if (route != null) edit((b) => b.addRoute(family, route, included: included));
  }

  List<Widget> routeSection(AddressFamily family, {required bool included}) {
    final routes = (builder.settings(family)?[included ? 'includedRoutes' : 'excludedRoutes'] as List?) ?? const <dynamic>[];
    return <Widget>[
      PSSection(
        key: ValueKey<String>('ip/${family.name}/${included ? 'included' : 'excluded'}'),
        children: <Widget>[
          for (var i = 0; i < routes.length; i++)
            _RouteRow(
              description: routeDescription(Map<String, dynamic>.from(routes[i] as Map)),
              onRemove: () => edit((b) => b.removeRoute(family, i, included: included)),
            ),
          PSRow(
            title: tr(included ? Strings.modulesIpRoutesInclude : Strings.modulesIpRoutesExclude),
            onTap: () => presentRoute(family, included: included),
          ),
        ],
      ),
    ];
  }

  return <Widget>[
    for (final family in AddressFamily.values) ...<Widget>[
      PSSection(
        header: family.label,
        footer: tr(Strings.modulesIpAddressFooter),
        children: <Widget>[
          PSTextRow(
            key: ValueKey<String>('ip/${family.name}/address'),
            label: tr(Strings.globalNounsAddress),
            value: builder.subnetText[family] ?? '',
            placeholder: family.destinationPlaceholder,
            keyboardType: TextInputType.url,
            onChanged: (value) => edit((b) => b.setSubnet(family, value)),
          ),
        ],
      ),
      ...routeSection(family, included: true),
      ...routeSection(family, included: false),
    ],
    PSSection(
      header: tr(Strings.globalNounsInterface),
      children: <Widget>[
        PSTextRow(
          key: const ValueKey<String>('ip/mtu'),
          label: 'MTU',
          value: builder.mtu,
          placeholder: '1500',
          keyboardType: TextInputType.number,
          onChanged: (value) => edit((b) => b.mtu = value),
        ),
      ],
    ),
  ];
}

/// `ThemeRemovableItemRow(isEditing: true)` around `ThemeCopiableText`.
class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.description, required this.onRemove});

  final String description;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        IconButton(
          tooltip: tr(Strings.globalActionsDelete),
          icon: const Icon(Icons.remove_circle, color: PSColors.error),
          onPressed: onRemove,
        ),
        Expanded(
          child: PSRow(
            title: description,
            trailing: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => copyToClipboard(context, description),
            ),
          ),
        ),
      ]);
}

/// IPView.RouteView, presented modally: Default toggle, destination and
/// gateway; OK submits only what upstream accepts.
class RouteDialog extends StatefulWidget {
  const RouteDialog({super.key, required this.family, required this.title});

  final AddressFamily family;
  final String title;

  @override
  State<RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<RouteDialog> {
  String _destination = '';
  String _gateway = '';
  bool _isDefault = false;

  void _submit() {
    final route = parseRoute(widget.family, isDefault: _isDefault, destination: _destination, gateway: _gateway);
    if (route != null) Navigator.of(context).pop(route);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        contentPadding: const .symmetric(vertical: 12),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: .min, children: <Widget>[
            PSToggleRow(
              title: tr(Strings.globalNounsDefault),
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
            ),
            if (!_isDefault) ...<Widget>[
              PSTextRow(
                key: const ValueKey<String>('route/destination'),
                label: tr(Strings.globalNounsDestination),
                value: _destination,
                placeholder: widget.family.destinationPlaceholder,
                keyboardType: TextInputType.url,
                onChanged: (value) => setState(() => _destination = value),
              ),
              PSTextRow(
                key: const ValueKey<String>('route/gateway'),
                label: tr(Strings.globalNounsGateway),
                value: _gateway,
                placeholder: widget.family.addressPlaceholder,
                keyboardType: TextInputType.url,
                onChanged: (value) => setState(() => _gateway = value),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ]),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr(Strings.globalActionsCancel))),
          TextButton(onPressed: _submit, child: Text(tr(Strings.globalNounsOk))),
        ],
      );
}
