// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The tray menu against upstream AppMenu.swift: item order, the toggles,
// reconnect/disconnect enabled only while the tunnel is up, the profile
// list with the active one checked, the icon per status, and what each
// item does.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/state/app_log.dart';
import 'package:passepartout/state/app_state.dart';
import 'package:passepartout/ui/desktop/app_menu.dart';
import 'package:passepartout/ui/desktop/tray_controller.dart';
import 'package:passepartout/ui/kit.dart';

TunnelProfile profile(String id, String name) => TunnelProfile(json: <String, dynamic>{
      'version': 1,
      'id': id,
      'name': name,
      'modules': <dynamic>[],
      'activeModulesIds': <dynamic>[],
    });

final ProfilesState twoProfiles = ProfilesState(
  profiles: <TunnelProfile>[profile('w', 'Work'), profile('h', 'Home')],
  isReady: true,
);

AppMenuModel model({
  ProfilesState? profiles,
  TunnelState tunnel = const TunnelState(),
  Preferences preferences = const Preferences(),
  bool launchesOnLogin = false,
}) =>
    AppMenuModel(
      profiles: profiles ?? twoProfiles,
      tunnel: tunnel,
      preferences: preferences,
      launchesOnLogin: launchesOnLogin,
    );

void main() {
  setUpAll(() {
    const DVI18n().loadAll(stringCatalogs.values);
    const DVI18n().useLocale(const LocaleTag('en'));
    AppLog.init();
  });

  group('the menu, as upstream AppMenu.body orders it', () {
    test('version, show, the two toggles, reconnect, disconnect, the profiles, about, quit', () {
      final List<DVTrayMenuItem> menu = buildAppMenu(model());
      final List<String> shape = <String>[
        for (final DVTrayMenuItem item in menu) item.isSeparator ? '---' : item.id,
      ];
      expect(shape, <String>[
        AppMenuIds.version,
        '---',
        AppMenuIds.show,
        AppMenuIds.launchesOnLogin,
        AppMenuIds.keepsInMenu,
        '---',
        AppMenuIds.reconnect,
        AppMenuIds.disconnect,
        '---',
        AppMenuIds.profilesHeader,
        // Sorted by name, as filteredHeaders is.
        '${AppMenuIds.profilePrefix}h',
        '${AppMenuIds.profilePrefix}w',
        '---',
        AppMenuIds.about,
        AppMenuIds.quit,
      ]);
    });

    test('the version line and the folder name are headers, never choices', () {
      final List<DVTrayMenuItem> menu = buildAppMenu(model());
      expect(menu.first.isHeader, isTrue);
      expect(menu.first.label, appVersionString);
      final DVTrayMenuItem folder = menu.firstWhere((DVTrayMenuItem i) => i.id == AppMenuIds.profilesHeader);
      expect(folder.isHeader, isTrue);
      expect(folder.label, tr(Strings.viewsAppFoldersDefault));
    });

    test('labels are upstream strings, quit naming the app', () {
      final Map<String, String> labels = <String, String>{
        for (final DVTrayMenuItem item in buildAppMenu(model())) item.id: item.label,
      };
      expect(labels[AppMenuIds.show], tr(Strings.globalActionsShow));
      expect(labels[AppMenuIds.launchesOnLogin], tr(Strings.viewsPreferencesLaunchesOnLogin));
      expect(labels[AppMenuIds.keepsInMenu], tr(Strings.viewsPreferencesKeepsInMenu));
      expect(labels[AppMenuIds.about], tr(Strings.globalNounsAbout));
      expect(labels[AppMenuIds.quit], 'Quit Passepartout');
    });

    test('no profiles: no profile section at all', () {
      final List<String> ids = <String>[
        for (final DVTrayMenuItem item in buildAppMenu(model(profiles: const ProfilesState(isReady: true)))) item.id,
      ];
      expect(ids, isNot(contains(AppMenuIds.profilesHeader)));
      expect(ids.where((String id) => id.startsWith(AppMenuIds.profilePrefix)), isEmpty);
    });

    test('the toggles are check marks that follow their settings', () {
      DVTrayMenuItem item(AppMenuModel m, String id) => buildAppMenu(m).firstWhere((DVTrayMenuItem i) => i.id == id);
      expect(item(model(), AppMenuIds.keepsInMenu).checked, isTrue, reason: 'keepsInMenu defaults on');
      expect(item(model(preferences: const Preferences(keepsInMenu: false)), AppMenuIds.keepsInMenu).checked, isFalse);
      expect(item(model(), AppMenuIds.launchesOnLogin).checked, isFalse);
      expect(item(model(launchesOnLogin: true), AppMenuIds.launchesOnLogin).checked, isTrue);
    });

    for (final (TunnelStatus status, bool actionable) in <(TunnelStatus, bool)>[
      (.disconnected, false),
      (.connecting, true),
      (.connected, true),
      (.disconnecting, false),
    ]) {
      test('reconnect and disconnect are ${actionable ? 'enabled' : 'disabled'} while ${status.name}', () {
        final List<DVTrayMenuItem> menu = buildAppMenu(model(tunnel: TunnelState(activeProfileId: 'w', status: status)));
        for (final String id in <String>[AppMenuIds.reconnect, AppMenuIds.disconnect]) {
          expect(menu.firstWhere((DVTrayMenuItem i) => i.id == id).enabled, actionable, reason: id);
        }
      });
    }

    test('the active profile is checked, others are not', () {
      final List<DVTrayMenuItem> menu =
          buildAppMenu(model(tunnel: const TunnelState(activeProfileId: 'w', status: .connecting)));
      final Map<String, bool?> checked = <String, bool?>{
        for (final DVTrayMenuItem item in menu)
          if (item.id.startsWith(AppMenuIds.profilePrefix)) item.id: item.checked,
      };
      expect(checked, <String, bool?>{'${AppMenuIds.profilePrefix}h': false, '${AppMenuIds.profilePrefix}w': true});
    });

    test('the framework accepts the menu: unique ids, every choice named', () async {
      final List<Object?> sent = <Object?>[];
      DVNativeBridge.register('tray.show', (Object? arguments) {
        sent.add(arguments);
        return true;
      });
      addTearDown(() {
        DVNativeBridge.unregister('tray.show');
        DVTray.reset();
      });
      await DV.Platform.tray.show(icon: TrayIcon.inactiveLight, menu: buildAppMenu(model()));
      expect(sent, hasLength(1));
    });
  });

  group('the icon, as upstream AppMenuImage picks it', () {
    test('per status, an error showing as disconnected', () {
      expect(appMenuImage(const TunnelState()), AppMenuImage.inactive);
      expect(appMenuImage(const TunnelState(activeProfileId: 'w', status: .connected)), AppMenuImage.active);
      expect(appMenuImage(const TunnelState(activeProfileId: 'w', status: .connecting)), AppMenuImage.pending);
      expect(appMenuImage(const TunnelState(activeProfileId: 'w', status: .disconnecting)), AppMenuImage.pending);
      expect(appMenuImage(const TunnelState(activeProfileId: 'w', lastErrorCode: 'x')), AppMenuImage.inactive);
    });

    test('macOS gets the template images, the other desktops the white ones', () {
      expect(TrayIcon.of(.active, template: true), TrayIcon.active);
      expect(TrayIcon.of(.active, template: false), TrayIcon.activeLight);
      expect(TrayIcon.of(.pending, template: false), TrayIcon.pendingLight);
    });

    test('every icon file exists, so a rename fails here rather than on a desktop', () {
      for (final TrayIcon icon in TrayIcon.values) {
        expect(File(icon.path).existsSync(), isTrue, reason: icon.path);
      }
    });
  });

  group('what choosing an item does', () {
    late List<String> done;
    late AppMenuActions actions;
    setUp(() {
      done = <String>[];
      actions = AppMenuActions(
        show: () async => done.add('show'),
        setLaunchesOnLogin: (bool on) async => done.add('login:$on'),
        setKeepsInMenu: (bool on) async => done.add('keep:$on'),
        reconnect: (TunnelProfile p) async => done.add('reconnect:${p.id}'),
        disconnect: () async => done.add('disconnect'),
        connect: (TunnelProfile p) async => done.add('connect:${p.id}'),
        about: () async => done.add('about'),
        quit: () async => done.add('quit'),
      );
    });

    test('a disconnected profile connects, the active one disconnects', () async {
      final AppMenuModel m = model(tunnel: const TunnelState(activeProfileId: 'w', status: .connected));
      await handleAppMenuSelection('${AppMenuIds.profilePrefix}h', m, actions);
      await handleAppMenuSelection('${AppMenuIds.profilePrefix}w', m, actions);
      expect(done, <String>['connect:h', 'disconnect']);
    });

    test('reconnect and disconnect act on the installed profile, and on nothing without one', () async {
      await handleAppMenuSelection(AppMenuIds.reconnect, model(), actions);
      await handleAppMenuSelection(AppMenuIds.disconnect, model(), actions);
      expect(done, isEmpty);
      final AppMenuModel up = model(tunnel: const TunnelState(activeProfileId: 'w', status: .connected));
      await handleAppMenuSelection(AppMenuIds.reconnect, up, actions);
      await handleAppMenuSelection(AppMenuIds.disconnect, up, actions);
      expect(done, <String>['reconnect:w', 'disconnect']);
    });

    test('the toggles flip their setting', () async {
      await handleAppMenuSelection(AppMenuIds.keepsInMenu, model(), actions);
      await handleAppMenuSelection(AppMenuIds.launchesOnLogin, model(launchesOnLogin: true), actions);
      expect(done, <String>['keep:false', 'login:false']);
    });

    test('show, about and quit', () async {
      for (final String id in <String>[AppMenuIds.show, AppMenuIds.about, AppMenuIds.quit]) {
        await handleAppMenuSelection(id, model(), actions);
      }
      expect(done, <String>['show', 'about', 'quit']);
    });

    test('a failure is logged rather than thrown into the tray callback', () async {
      final AppMenuActions failing = AppMenuActions(
        show: () async => throw StateError('no window'),
        setLaunchesOnLogin: (_) async {},
        setKeepsInMenu: (_) async {},
        reconnect: (_) async {},
        disconnect: () async {},
        connect: (_) async {},
        about: () async {},
        quit: () async {},
      );
      await expectLater(handleAppMenuSelection(AppMenuIds.show, model(), failing), completes);
    });
  });
}
