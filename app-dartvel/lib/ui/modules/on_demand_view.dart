// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// On-demand module editor: upstream OnDemandView.swift + OnDemandModule.Builder
// (PartoutCore OnDemandModule+Extensions.swift). Writes `OnDemandModule`.
//
// Upstream shows the Mobile and "Ethernet (Mac/TV)" toggles on every
// platform, so this does too. Upstream fills a new SSID row with the current
// Wi-Fi name (CoreLocation); there is no Dartvel API for that yet, so a new
// row starts empty (see docs/DARTVEL-GAPS.md).

import 'package:flutter/material.dart';

import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'common/editable_list_section.dart';
import 'common/module_builder_cache.dart';
import 'module_view.dart';

/// `OnDemandModule.Policy`, in upstream's picker order (paid builds).
const List<String> onDemandPolicies = <String>['any', 'excluding', 'including'];

String onDemandPolicyLabel(String policy) => switch (policy) {
      'excluding' => tr(Strings.entitiesOnDemandPolicyExcluding),
      'including' => tr(Strings.entitiesOnDemandPolicyIncluding),
      _ => tr(Strings.entitiesOnDemandPolicyAny),
    };

/// One Wi-Fi row: SSID and whether it is on.
typedef SsidEntry = ({String name, bool on});

/// `OnDemandModule.Builder`, with `withSSIDs` kept as ordered rows.
final class OnDemandBuilder {
  OnDemandBuilder({this.policy = 'any', List<ListItem<SsidEntry>>? ssids, List<String>? otherNetworks})
      : ssids = ssids ?? <ListItem<SsidEntry>>[],
        otherNetworks = otherNetworks ?? <String>[];

  factory OnDemandBuilder.fromJson(Map<String, dynamic> value) => OnDemandBuilder(
        policy: value['policy'] as String? ?? 'any',
        ssids: <ListItem<SsidEntry>>[
          for (final entry in ((value['withSSIDs'] as Map?) ?? const <String, dynamic>{}).entries)
            ListItem<SsidEntry>((name: '${entry.key}', on: entry.value == true)),
        ],
        otherNetworks: <String>[for (final network in (value['withOtherNetworks'] as List?) ?? const <dynamic>[]) '$network'],
      );

  String policy;
  List<ListItem<SsidEntry>> ssids;
  List<String> otherNetworks;

  bool _has(String network) => otherNetworks.contains(network);

  void _set(String network, bool value) {
    otherNetworks = <String>[...otherNetworks.where((other) => other != network), if (value) network];
  }

  bool get withMobileNetwork => _has('mobile');
  set withMobileNetwork(bool value) => _set('mobile', value);

  bool get withEthernetNetwork => _has('ethernet');
  set withEthernetNetwork(bool value) => _set('ethernet', value);

  /// `allSSIDs` setter: SSIDs that are new become off; a row renamed to an
  /// SSID already listed takes that SSID's state.
  void setSSIDs(List<ListItem<SsidEntry>> rows) {
    final previous = <int, SsidEntry>{for (final row in ssids) row.id: row.value};
    final next = <ListItem<SsidEntry>>[];
    for (final row in rows) {
      final before = previous[row.id];
      if (before != null && before.name != row.value.name) {
        final existing = ssids.where((other) => other.id != row.id && other.value.name == row.value.name).firstOrNull;
        next.add(row.copyWith((name: row.value.name, on: existing?.value.on ?? false)));
      } else {
        next.add(row);
      }
    }
    ssids = next;
  }

  /// `isSSIDOn(_:)` setter: `withSSIDs[ssid] = value`.
  void setSSIDOn(String name, bool value) {
    ssids = <ListItem<SsidEntry>>[
      for (final row in ssids) row.value.name == name ? row.copyWith((name: name, on: value)) : row,
    ];
  }

  /// `withSSIDs` as written: one key per SSID, first row wins.
  Map<String, bool> get withSSIDs {
    final map = <String, bool>{};
    for (final row in ssids) {
      map.putIfAbsent(row.value.name, () => row.value.on);
    }
    return map;
  }

  /// `build()`.
  Map<String, Object?> get changes => <String, Object?>{
        'policy': policy,
        'withSSIDs': withSSIDs,
        'withOtherNetworks': <String>[...otherNetworks],
      };
}

final ModuleBuilderCache<OnDemandBuilder> onDemandBuilders = ModuleBuilderCache<OnDemandBuilder>(OnDemandBuilder.fromJson);

/// Upstream's `policyFooterDescription`.
String onDemandPolicyFooter(String policy) => tr(Strings.modulesOnDemandPolicyFooter, <Object>[
      switch (policy) {
        'including' => tr(Strings.modulesOnDemandPolicyFooterIncluding),
        'excluding' => tr(Strings.modulesOnDemandPolicyFooterExcluding),
        _ => tr(Strings.modulesOnDemandPolicyFooterAny),
      },
    ]);

/// On-demand module sections.
List<Widget> onDemandSections(BuildContext context, ModuleViewArgs args) {
  final builder = onDemandBuilders.resolve(args.module);
  void edit(void Function(OnDemandBuilder) change) {
    change(builder);
    args.onChanged(onDemandBuilders.write(args.module, builder, builder.changes));
  }

  return <Widget>[
    PSSection(
      footer: onDemandPolicyFooter(builder.policy),
      children: <Widget>[
        PSPickerRow<String>(
          title: tr(Strings.modulesOnDemandPolicy),
          value: builder.policy,
          options: onDemandPolicies,
          label: onDemandPolicyLabel,
          onChanged: (value) => edit((b) => b.policy = value),
        ),
      ],
    ),
    if (builder.policy != 'any') ...<Widget>[
      PSSection(
        header: tr(Strings.globalNounsNetworks),
        footer: tr(Strings.modulesOnDemandNetworksFooter),
        children: <Widget>[
          PSToggleRow(
            title: tr(Strings.modulesOnDemandMobile),
            value: builder.withMobileNetwork,
            onChanged: (value) => edit((b) => b.withMobileNetwork = value),
          ),
          PSToggleRow(
            title: '${tr(Strings.modulesOnDemandEthernet)} (Mac/TV)',
            value: builder.withEthernetNetwork,
            onChanged: (value) => edit((b) => b.withEthernetNetwork = value),
          ),
        ],
      ),
      EditableListSection<SsidEntry>(
        key: const ValueKey<String>('onDemand/ssids'),
        header: 'Wi-Fi',
        addTitle: tr(Strings.modulesOnDemandSsidAdd),
        items: builder.ssids,
        emptyValue: () => (name: '', on: false),
        isEmptyValue: (value) => value.name.isEmpty,
        onChanged: (rows) => edit((b) => b.setSSIDs(rows)),
        itemBuilder: (context, item, setValue) => Row(children: <Widget>[
          Expanded(
            child: ListItemTextField(
              key: ValueKey<String>('onDemand/ssids/${item.id}'),
              value: item.value.name,
              placeholder: tr(Strings.placeholdersOnDemandSsid),
              semanticLabel: 'Wi-Fi',
              onChanged: (name) => setValue((name: name, on: item.value.on)),
            ),
          ),
          Semantics(
            label: item.value.name,
            child: Switch.adaptive(
              key: ValueKey<String>('onDemand/ssids/${item.id}/on'),
              value: builder.withSSIDs[item.value.name] ?? false,
              onChanged: (value) => edit((b) => b.setSSIDOn(item.value.name, value)),
            ),
          ),
        ]),
      ),
    ],
  ];
}
