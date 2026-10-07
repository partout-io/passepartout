// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Module types, exactly as `TaggedModule.type` spells them in
/// `partout/scripts/openapi.yaml`.
abstract final class ModuleType {
  static const String openVPN = 'OpenVPN';
  static const String wireGuard = 'WireGuard';
  static const String dns = 'DNS';
  static const String httpProxy = 'HTTPProxy';
  static const String ip = 'IP';
  static const String onDemand = 'OnDemand';
  static const String custom = 'Custom';

  /// A connection module carries the tunnel itself; a profile has at most one active.
  static bool isConnection(String type) => type == openVPN || type == wireGuard;

  /// The types "Add module" offers, in upstream's order.
  static const List<String> addable = <String>[dns, httpProxy, ip, onDemand, openVPN, wireGuard];
}

String newUniqueId() => const Uuid().v4().toUpperCase();

/// Lossless wire model for `Profile` in openapi.yaml.
///
/// Fields this app does not edit (private keys, userInfo, unknown module
/// options) survive every edit untouched, because the JSON is the model.
class const TunnelProfile({required final Map<String, dynamic> json}) {
  factory TunnelProfile.decode(String text) {
    final value = jsonDecode(text) as Map<String, dynamic>;
    if (value['id'] is! String || value['name'] is! String ||
        value['modules'] is! List || value['activeModulesIds'] is! List) {
      throw const FormatException('Invalid Partout profile');
    }
    return TunnelProfile(json: value);
  }

  /// A new, empty profile, like "Empty profile" in the add menu.
  factory TunnelProfile.empty(String name) => TunnelProfile(json: <String, dynamic>{
        'version': 1,
        'id': newUniqueId(),
        'name': name,
        'modules': <dynamic>[],
        'activeModulesIds': <dynamic>[],
      });

  String get id => json['id'] as String;
  String get name => json['name'] as String;
  List<TaggedModule> get modules => (json['modules'] as List)
      .map((value) => TaggedModule(json: Map<String, dynamic>.from(value as Map)))
      .toList();
  Set<String> get activeModuleIds => (json['activeModulesIds'] as List).cast<String>().toSet();
  bool isActive(String moduleId) => activeModuleIds.contains(moduleId);

  TaggedModule? module(String moduleId) {
    for (final module in modules) {
      if (module.id == moduleId) return module;
    }
    return null;
  }

  /// The active connection module (OpenVPN or WireGuard), if any.
  TaggedModule? get activeConnection {
    for (final module in modules) {
      if (ModuleType.isConnection(module.type) && isActive(module.id)) return module;
    }
    return null;
  }

  /// "OpenVPN, DNS" — upstream's `localizedDescription(optionalStyle: .moduleTypes)`.
  String get moduleSummary => modules.where((m) => isActive(m.id)).map((m) => m.typeLabel).join(', ');

  bool get disconnectsOnSleep => (json['behavior'] as Map?)?['disconnectsOnSleep'] == true;
  bool get includesAllNetworks => (json['behavior'] as Map?)?['includesAllNetworks'] == true;

  String encode() => jsonEncode(json);

  TunnelProfile _with(Map<String, dynamic> changes) => TunnelProfile(json: <String, dynamic>{...json, ...changes});

  TunnelProfile renamed(String name) => _with(<String, dynamic>{'name': name});

  TunnelProfile withBehavior({bool? disconnectsOnSleep, bool? includesAllNetworks}) => _with(<String, dynamic>{
        'behavior': <String, dynamic>{
          ...?(json['behavior'] as Map?)?.cast<String, dynamic>(),
          'disconnectsOnSleep': disconnectsOnSleep ?? this.disconnectsOnSleep,
          if (includesAllNetworks != null) 'includesAllNetworks': includesAllNetworks,
        },
      });

  TunnelProfile _withModules(List<TaggedModule> modules, Set<String> active) => _with(<String, dynamic>{
        'modules': modules.map((m) => m.json).toList(),
        'activeModulesIds': modules.map((m) => m.id).where(active.contains).toList(),
      });

  /// Adds or replaces [module] by id. A new module becomes active; activating
  /// a connection module deactivates any other connection, as upstream does.
  TunnelProfile savingModule(TaggedModule module, {bool? activate}) {
    final list = modules;
    final index = list.indexWhere((m) => m.id == module.id);
    final isNew = index < 0;
    if (isNew) {
      list.add(module);
    } else {
      list[index] = module;
    }
    var active = activeModuleIds;
    if (activate ?? isNew) active = _activating(active, list, module);
    return _withModules(list, active);
  }

  TunnelProfile togglingModule(String moduleId) {
    final list = modules;
    final target = list.firstWhere((m) => m.id == moduleId);
    final active = activeModuleIds;
    if (active.contains(moduleId)) {
      return _withModules(list, active..remove(moduleId));
    }
    return _withModules(list, _activating(active, list, target));
  }

  Set<String> _activating(Set<String> active, List<TaggedModule> list, TaggedModule module) {
    final next = <String>{...active, module.id};
    if (ModuleType.isConnection(module.type)) {
      for (final other in list) {
        if (other.id != module.id && ModuleType.isConnection(other.type)) next.remove(other.id);
      }
    }
    return next;
  }

  TunnelProfile removingModule(String moduleId) {
    final list = modules..removeWhere((m) => m.id == moduleId);
    return _withModules(list, activeModuleIds..remove(moduleId));
  }

  TunnelProfile movingModule(int from, int to) {
    final list = modules;
    final module = list.removeAt(from);
    list.insert(to > from ? to - 1 : to, module);
    return _withModules(list, activeModuleIds);
  }

  /// A copy with fresh ids, for "Duplicate".
  TunnelProfile duplicated(String name) {
    final ids = <String, String>{for (final m in modules) m.id: newUniqueId()};
    final list = modules.map((m) => m.withId(ids[m.id]!)).toList();
    return TunnelProfile(json: <String, dynamic>{
      ...json,
      'id': newUniqueId(),
      'name': name,
      'modules': list.map((m) => m.json).toList(),
      'activeModulesIds': activeModuleIds.map((id) => ids[id]).whereType<String>().toList(),
    });
  }
}

/// `TaggedModule`: `{"type": "DNS", "value": {...}}`.
class const TaggedModule({required final Map<String, dynamic> json}) {
  factory TaggedModule.of(String type, Map<String, dynamic> value) =>
      TaggedModule(json: <String, dynamic>{'type': type, 'value': value});

  /// A new module of [type] with upstream's defaults for an empty editor.
  factory TaggedModule.empty(String type) => TaggedModule.of(type, switch (type) {
        ModuleType.dns => <String, dynamic>{
            'id': newUniqueId(),
            'protocolType': <String, dynamic>{'type': 'cleartext'},
            'servers': <dynamic>[],
          },
        ModuleType.httpProxy => <String, dynamic>{'id': newUniqueId(), 'bypassDomains': <dynamic>[]},
        ModuleType.ip => <String, dynamic>{'id': newUniqueId()},
        ModuleType.onDemand => <String, dynamic>{
            'id': newUniqueId(),
            'policy': 'any',
            'withSSIDs': <String, dynamic>{},
            'withOtherNetworks': <dynamic>[],
          },
        _ => <String, dynamic>{'id': newUniqueId()},
      });

  String get type => json['type'] as String;
  Map<String, dynamic> get value => Map<String, dynamic>.from(json['value'] as Map);
  String get id => value['id'] as String;

  /// Upstream shows type names unlocalised: "OpenVPN", "WireGuard", "DNS",
  /// "HTTP Proxy", "IP", "On-demand".
  String get typeLabel => switch (type) {
        ModuleType.httpProxy => 'HTTP Proxy',
        ModuleType.onDemand => 'On-demand',
        _ => type,
      };

  TaggedModule withValue(Map<String, dynamic> value) => TaggedModule.of(type, value);

  /// Sets [key] to [newValue], or removes it when null (never writes nulls:
  /// openapi.yaml has `additionalProperties: false` and no nullable fields).
  TaggedModule withField(String key, Object? newValue) {
    final next = value;
    if (newValue == null) {
      next.remove(key);
    } else {
      next[key] = newValue;
    }
    return withValue(next);
  }

  TaggedModule withId(String id) => withField('id', id);
}
