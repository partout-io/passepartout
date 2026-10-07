// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// App state, held as immutable values in `DV.global`. Screens read them with
// `context.global<T>()` and rebuild when a store replaces the value.
//
// Profiles live on the device, one JSON file per profile under
// `profiles/<id>.json` in `DV.Platform.fileStorage` — never on a server, since
// they carry private keys. This mirrors upstream's file-backed
// `FileProfileRepository` on Android.

import 'dart:async';
import 'dart:convert';

import '../dartvel_client/dartvel_client.dart';
import '../domain/profile.dart';
import '../platform/vpn_service.dart';
import 'app_log.dart';

// ---------------------------------------------------------------------------
// Values

class const ProfilesState({
  final List<TunnelProfile> profiles = const <TunnelProfile>[],
  final bool isReady = false,
  final String search = '',
}) {
  /// Sorted by name like upstream's `filteredHeaders`, filtered by [search].
  List<TunnelProfile> get filtered {
    final query = search.trim().toLowerCase();
    final list = profiles.where((p) => query.isEmpty || p.name.toLowerCase().contains(query)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  bool get hasProfiles => profiles.isNotEmpty;

  TunnelProfile? byId(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  /// "My profile", "My profile 2"... — upstream's `firstUniqueName(from:)`.
  String firstUniqueName(String base) {
    final names = profiles.map((p) => p.name).toSet();
    if (!names.contains(base)) return base;
    var index = 2;
    while (names.contains('$base $index')) {
      index++;
    }
    return '$base $index';
  }
}

/// ConnectionStatus in openapi.yaml.
enum TunnelStatus { disconnected, connecting, connected, disconnecting }

class const TunnelState({
  final String? activeProfileId,
  final TunnelStatus status = .disconnected,
  final int received = 0,
  final int sent = 0,
  final String? lastErrorCode,
}) {
  TunnelStatus statusOf(String profileId) => profileId == activeProfileId ? status : .disconnected;
  bool isActive(String profileId) => profileId == activeProfileId && status != .disconnected;
}

enum ProfilesLayout { list, grid }

enum SystemAppearance { system, light, dark }

/// Upstream `AppPreferences` + `UserPreferences` subset that applies here.
class const Preferences({
  final ProfilesLayout layout = .list,
  final bool pinsActiveProfile = true,
  final bool keepsInMenu = true,
  final bool launchesOnLogin = false,
  final bool dnsFallsBack = true,
  final SystemAppearance appearance = .system,
  final bool logsPrivateData = false,
  final bool extensiveLogging = false,
}) {
  factory Preferences.fromJson(Map<String, dynamic> json) => Preferences(
        layout: json['layout'] == 'grid' ? .grid : .list,
        pinsActiveProfile: json['pinsActiveProfile'] as bool? ?? true,
        keepsInMenu: json['keepsInMenu'] as bool? ?? true,
        launchesOnLogin: json['launchesOnLogin'] as bool? ?? false,
        dnsFallsBack: json['dnsFallsBack'] as bool? ?? true,
        appearance: SystemAppearance.values.asNameMap()[json['appearance']] ?? .system,
        logsPrivateData: json['logsPrivateData'] as bool? ?? false,
        extensiveLogging: json['extensiveLogging'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'layout': layout.name,
        'pinsActiveProfile': pinsActiveProfile,
        'keepsInMenu': keepsInMenu,
        'launchesOnLogin': launchesOnLogin,
        'dnsFallsBack': dnsFallsBack,
        'appearance': appearance.name,
        'logsPrivateData': logsPrivateData,
        'extensiveLogging': extensiveLogging,
      };

  Preferences copyWith({
    ProfilesLayout? layout,
    bool? pinsActiveProfile,
    bool? keepsInMenu,
    bool? launchesOnLogin,
    bool? dnsFallsBack,
    SystemAppearance? appearance,
    bool? logsPrivateData,
    bool? extensiveLogging,
  }) =>
      Preferences(
        layout: layout ?? this.layout,
        pinsActiveProfile: pinsActiveProfile ?? this.pinsActiveProfile,
        keepsInMenu: keepsInMenu ?? this.keepsInMenu,
        launchesOnLogin: launchesOnLogin ?? this.launchesOnLogin,
        dnsFallsBack: dnsFallsBack ?? this.dnsFallsBack,
        appearance: appearance ?? this.appearance,
        logsPrivateData: logsPrivateData ?? this.logsPrivateData,
        extensiveLogging: extensiveLogging ?? this.extensiveLogging,
      );
}

// ---------------------------------------------------------------------------
// Stores

const String _profilesPrefix = 'profiles/';
const String _preferencesKey = 'preferences.json';

DVStorage get _disk => DV.Platform.fileStorage;

abstract final class ProfileStore {
  static ProfilesState get state => DV.global<ProfilesState>();
  static void _set(ProfilesState next) => DV.global<ProfilesState>(next);

  static void init() => DV.global<ProfilesState>(const ProfilesState());

  static Future<void> load() async {
    final profiles = <TunnelProfile>[];
    try {
      for (final key in await _disk.list(prefix: _profilesPrefix)) {
        if (!key.endsWith('.json')) continue;
        try {
          profiles.add(TunnelProfile.decode(utf8.decode(await _disk.get(key))));
        } on Object catch (error) {
          AppLog.warning('Skipping unreadable profile $key: $error');
        }
      }
    } on Object catch (error) {
      AppLog.error('Unable to list profiles: $error');
    }
    _set(ProfilesState(profiles: profiles, isReady: true, search: state.search));
  }

  static void search(String text) =>
      _set(ProfilesState(profiles: state.profiles, isReady: state.isReady, search: text));

  static Future<void> save(TunnelProfile profile) async {
    await _disk.put('$_profilesPrefix${profile.id}.json', utf8.encode(profile.encode()),
        contentType: 'application/json');
    final list = state.profiles.where((p) => p.id != profile.id).toList()..add(profile);
    _set(ProfilesState(profiles: list, isReady: true, search: state.search));
  }

  static Future<void> remove(String id) async {
    await _disk.delete('$_profilesPrefix$id.json');
    if (TunnelStore.state.activeProfileId == id) await TunnelStore.disconnect();
    final list = state.profiles.where((p) => p.id != id).toList();
    _set(ProfilesState(profiles: list, isReady: true, search: state.search));
  }

  static Future<TunnelProfile> duplicate(String id) async {
    final source = state.byId(id)!;
    final copy = source.duplicated(state.firstUniqueName(source.name));
    await save(copy);
    return copy;
  }

  /// Imports an OpenVPN/WireGuard configuration through Partout and saves it.
  static Future<TunnelProfile> importText(String text, {String? name}) async {
    final base = (name == null || name.trim().isEmpty) ? 'Imported profile' : name.trim();
    final profile = await VpnService.instance.importProfile(text, state.firstUniqueName(base));
    await save(profile);
    return profile;
  }
}

abstract final class TunnelStore {
  static TunnelState get state => DV.global<TunnelState>();
  static void _set(TunnelState next) => DV.global<TunnelState>(next);

  static void init() => DV.global<TunnelState>(const TunnelState());

  /// Connects [profile], disconnecting any other first (one active profile).
  static Future<void> connect(TunnelProfile profile) async {
    if (state.activeProfileId != null && state.activeProfileId != profile.id) await disconnect();
    _set(TunnelState(activeProfileId: profile.id, status: .connecting));
    try {
      await VpnService.instance.connect(profile, onStatus: _onStatus);
    } on Object catch (error) {
      _set(TunnelState(activeProfileId: profile.id, lastErrorCode: '$error'));
      rethrow;
    }
  }

  static Future<void> disconnect() async {
    final id = state.activeProfileId;
    if (id == null) return;
    _set(TunnelState(activeProfileId: id, status: .disconnecting));
    try {
      await VpnService.instance.disconnect();
    } finally {
      _set(const TunnelState());
    }
  }

  static Future<void> toggle(TunnelProfile profile) =>
      state.isActive(profile.id) ? disconnect() : connect(profile);

  static Future<void> reconnect(TunnelProfile profile) async {
    await disconnect();
    await connect(profile);
  }

  static void _onStatus(TunnelEvent event) {
    final current = state;
    _set(TunnelState(
      activeProfileId: event.status == .disconnected && event.errorCode == null ? null : current.activeProfileId,
      status: event.status ?? current.status,
      received: event.received ?? current.received,
      sent: event.sent ?? current.sent,
      lastErrorCode: event.errorCode ?? current.lastErrorCode,
    ));
  }
}

abstract final class PreferencesStore {
  static Preferences get state => DV.global<Preferences>();

  static void init() => DV.global<Preferences>(const Preferences());

  static Future<void> load() async {
    try {
      if (await _disk.exists(_preferencesKey)) {
        DV.global<Preferences>(Preferences.fromJson(
            jsonDecode(utf8.decode(await _disk.get(_preferencesKey))) as Map<String, dynamic>));
      }
    } on Object catch (error) {
      AppLog.warning('Unable to read preferences: $error');
    }
  }

  static Future<void> update(Preferences Function(Preferences) change) async {
    final next = change(state);
    DV.global<Preferences>(next);
    await _disk.put(_preferencesKey, utf8.encode(jsonEncode(next.toJson())), contentType: 'application/json');
  }
}
