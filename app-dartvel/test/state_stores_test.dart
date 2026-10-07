// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Unit tests of lib/state/app_state.dart: ProfilesState, Preferences, and the
// file-backed ProfileStore and PreferencesStore over an in-memory
// DV.Platform.fileStorage (DVDeviceStorage.useAdapters).

import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/state/app_state.dart';

import 'support/app_harness.dart';

bool get _hasEngine {
  final path = io.Platform.environment['PARTOUT_LIBRARY'];
  return path != null && io.File(path).existsSync();
}

TunnelProfile _named(String name) => TunnelProfile.empty(name).savingModule(TaggedModule.empty(ModuleType.dns));

void main() {
  group('ProfilesState', () {
    test('filtered sorts case-insensitively and searches', () {
      final state = ProfilesState(profiles: <TunnelProfile>[_named('beta'), _named('Alpha'), _named('gamma ray')]);
      expect(state.filtered.map((p) => p.name), <String>['Alpha', 'beta', 'gamma ray']);
      final searching = ProfilesState(profiles: state.profiles, search: '  RAY ');
      expect(searching.filtered.map((p) => p.name), <String>['gamma ray']);
      expect(ProfilesState(profiles: state.profiles, search: 'zzz').filtered, isEmpty);
      expect(state.hasProfiles, isTrue);
      expect(const ProfilesState().hasProfiles, isFalse);
      expect(state.byId(state.profiles.first.id)!.name, 'beta');
      expect(state.byId('missing'), isNull);
    });

    test('firstUniqueName', () {
      final state = ProfilesState(profiles: <TunnelProfile>[_named('My profile'), _named('My profile 2'), _named('Other')]);
      expect(state.firstUniqueName('New'), 'New');
      expect(state.firstUniqueName('My profile'), 'My profile 3');
      expect(state.firstUniqueName('Other'), 'Other 2');
    });
  });

  group('Preferences', () {
    test('defaults', () {
      const preferences = Preferences();
      expect(preferences.layout, ProfilesLayout.list);
      expect(preferences.pinsActiveProfile, isTrue);
      expect(preferences.keepsInMenu, isTrue);
      expect(preferences.launchesOnLogin, isFalse);
      expect(preferences.dnsFallsBack, isTrue);
      expect(preferences.appearance, SystemAppearance.system);
      expect(preferences.logsPrivateData, isFalse);
      expect(preferences.extensiveLogging, isFalse);
      expect(Preferences.fromJson(<String, dynamic>{}).toJson(), preferences.toJson());
      expect(Preferences.fromJson(<String, dynamic>{'appearance': 'neon', 'layout': 'x'}).toJson(), preferences.toJson());
    });

    test('JSON round trip of every field', () {
      const changed = Preferences(
        layout: .grid,
        pinsActiveProfile: false,
        keepsInMenu: false,
        launchesOnLogin: true,
        dnsFallsBack: false,
        appearance: .dark,
        logsPrivateData: true,
        extensiveLogging: true,
      );
      final json = jsonDecode(jsonEncode(changed.toJson())) as Map<String, dynamic>;
      expect(Preferences.fromJson(json).toJson(), changed.toJson());
      expect(const Preferences().copyWith(appearance: .light).appearance, SystemAppearance.light);
      expect(changed.copyWith().toJson(), changed.toJson());
    });
  });

  group('stores over device storage', () {
    late DVMemoryFileStorageAdapter disk;

    setUp(() {
      disk = DVMemoryFileStorageAdapter();
      DVDeviceStorage.useAdapters(disk);
      setUpApp();
    });
    tearDown(DVDeviceStorage.reset);

    test('save, load, remove', () async {
      final profile = _named('Home').withBehavior(disconnectsOnSleep: true);
      await ProfileStore.save(profile);
      expect(await disk.list(prefix: 'profiles/'), <String>['profiles/${profile.id}.json']);
      expect(ProfileStore.state.isReady, isTrue);
      expect(ProfileStore.state.byId(profile.id)!.json, profile.json);

      // Saving again replaces, not duplicates.
      await ProfileStore.save(profile.renamed('Home 2'));
      expect(ProfileStore.state.profiles.length, 1);
      expect(ProfileStore.state.profiles.single.name, 'Home 2');

      ProfileStore.init();
      expect(ProfileStore.state.isReady, isFalse);
      await disk.put('profiles/broken.json', utf8.encode('{not json'));
      await disk.put('profiles/readme.txt', utf8.encode('ignored'));
      await ProfileStore.load();
      expect(ProfileStore.state.isReady, isTrue);
      expect(ProfileStore.state.profiles.map((p) => p.name), <String>['Home 2'], reason: 'skips unreadable files');
      expect(ProfileStore.state.profiles.single.disconnectsOnSleep, isTrue);

      await ProfileStore.remove(profile.id);
      expect(await disk.exists('profiles/${profile.id}.json'), isFalse);
      expect(ProfileStore.state.byId(profile.id), isNull);
    });

    test('search is kept across saves', () async {
      ProfileStore.search('ho');
      await ProfileStore.save(_named('Home'));
      await ProfileStore.save(_named('Work'));
      expect(ProfileStore.state.search, 'ho');
      expect(ProfileStore.state.filtered.map((p) => p.name), <String>['Home']);
    });

    test('duplicate saves a uniquely named copy', () async {
      final profile = _named('Home');
      await ProfileStore.save(profile);
      final copy = await ProfileStore.duplicate(profile.id);
      expect(copy.name, 'Home 2');
      expect(copy.id, isNot(profile.id));
      expect((await ProfileStore.duplicate(profile.id)).name, 'Home 3');
      expect(await disk.list(prefix: 'profiles/'), hasLength(3));
    });

    test('PreferencesStore round trip', () async {
      await PreferencesStore.load();
      expect(PreferencesStore.state.toJson(), const Preferences().toJson(), reason: 'no file yet');
      await PreferencesStore.update((p) => p.copyWith(layout: .grid, appearance: .dark));
      expect(await disk.exists('preferences.json'), isTrue);
      PreferencesStore.init();
      expect(PreferencesStore.state.layout, ProfilesLayout.list);
      await PreferencesStore.load();
      expect(PreferencesStore.state.layout, ProfilesLayout.grid);
      expect(PreferencesStore.state.appearance, SystemAppearance.dark);

      await disk.put('preferences.json', utf8.encode('[]'));
      PreferencesStore.init();
      await PreferencesStore.load();
      expect(PreferencesStore.state.toJson(), const Preferences().toJson(), reason: 'unreadable file keeps defaults');
    });

    test('importText imports real configurations through Partout', () async {
      final ovpn = io.File('test/fixtures/sample.ovpn').readAsStringSync();
      final first = await ProfileStore.importText(ovpn, name: ' Office ');
      expect(first.name, 'Office');
      expect(first.activeConnection!.type, ModuleType.openVPN);
      final second = await ProfileStore.importText(ovpn, name: 'Office');
      expect(second.name, 'Office 2');
      final unnamed = await ProfileStore.importText(io.File('test/fixtures/sample.conf').readAsStringSync());
      expect(unnamed.name, 'Imported profile');
      expect(unnamed.activeConnection!.type, ModuleType.wireGuard);
      expect(await disk.list(prefix: 'profiles/'), hasLength(3));
      await expectLater(ProfileStore.importText('not a configuration'), throwsA(anything));
      expect(ProfileStore.state.profiles, hasLength(3));
    }, skip: _hasEngine ? false : 'PARTOUT_LIBRARY not set');
  });

  test('DV.global holds the stores', () {
    setUpApp();
    expect(DV.global<ProfilesState>().profiles, isEmpty);
  });
}
