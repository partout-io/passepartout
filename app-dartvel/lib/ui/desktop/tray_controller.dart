// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The tray icon on macOS, Windows and Linux: shows [buildAppMenu] and the
// [appMenuImage] icon, and carries out what is chosen.
//
// Upstream inserts the menu-bar extra only while "Keep in menu bar" is on,
// and then keeps the app running when its window closes
// (`applicationShouldTerminateAfterLastWindowClosed` answers
// `!keepsInMenu`). The same here: keepsInMenu shows the tray and sets
// `DVWindowManager.exitPolicy` to explicit, so closing the window hides it;
// off, the tray goes and closing the window quits again.
//
// The menu is rebuilt when ProfilesState, TunnelState or Preferences is
// replaced. DV.global has no listener outside a widget, and the tray must
// follow the tunnel while the window is hidden (when no frame is drawn), so
// a timer compares the three values by identity -- the stores replace them,
// never mutate them -- and redraws only when one changed.

import 'dart:async';
import 'dart:ui' show AppExitType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../state/app_log.dart';
import '../../state/app_state.dart';
import 'app_menu.dart';

/// What choosing an item does. Separate from the tray so the routing is
/// tested without one.
class const AppMenuActions({
  required final Future<void> Function() show,
  required final Future<void> Function(bool enabled) setLaunchesOnLogin,
  required final Future<void> Function(bool enabled) setKeepsInMenu,
  required final Future<void> Function(TunnelProfile profile) reconnect,
  required final Future<void> Function() disconnect,
  required final Future<void> Function(TunnelProfile profile) connect,
  required final Future<void> Function() about,
  required final Future<void> Function() quit,
});

/// Carries out item [id] of the menu built from [model]. Upstream's
/// handlers, one for one; a failure is logged as upstream's pspLog does.
Future<void> handleAppMenuSelection(String id, AppMenuModel model, AppMenuActions actions) async {
  final TunnelState tunnel = model.tunnel;
  final TunnelProfile? installed = tunnel.activeProfileId == null ? null : model.profiles.byId(tunnel.activeProfileId!);
  try {
    switch (id) {
      case AppMenuIds.show:
        await actions.show();
      case AppMenuIds.launchesOnLogin:
        await actions.setLaunchesOnLogin(!model.launchesOnLogin);
      case AppMenuIds.keepsInMenu:
        await actions.setKeepsInMenu(!model.preferences.keepsInMenu);
      case AppMenuIds.reconnect:
        if (installed != null) await actions.reconnect(installed);
      case AppMenuIds.disconnect:
        if (installed != null) await actions.disconnect();
      case AppMenuIds.about:
        await actions.about();
      case AppMenuIds.quit:
        await actions.quit();
      default:
        if (!id.startsWith(AppMenuIds.profilePrefix)) return;
        final TunnelProfile? profile = model.profiles.byId(id.substring(AppMenuIds.profilePrefix.length));
        if (profile == null) return;
        // toggleProfile: the item shows whether the profile is active, so
        // choosing it asks for the other state.
        final bool isOn = tunnel.statusOf(profile.id) == .disconnected;
        if (isOn) {
          await actions.connect(profile);
        } else {
          await actions.disconnect();
        }
    }
  } on Object catch (error) {
    AppLog.error('Unable to run "$id" from the menu: $error');
  }
}

/// Whether this target has a tray: the three desktops, never the web.
bool get hasDesktopTray =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

class TrayController {
  TrayController._();

  static final TrayController instance = TrayController._();

  Timer? _watch;
  ProfilesState? _profiles;
  TunnelState? _tunnel;
  Preferences? _preferences;
  bool _launchesOnLogin = false;
  AppMenuModel? _model;
  bool _shown = false;

  bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> start() async {
    if (!hasDesktopTray) return;
    // The platform bindings are registered by configureDartvelRuntime,
    // which the generated router runs on the app's first build -- after
    // main() has called this, on a slow start. Wait for it.
    if (!await _bindingsReady()) {
      AppLog.warning('No tray on this desktop: the tray binding is not registered.');
      return;
    }
    _launchesOnLogin = await _readLaunchesOnLogin();
    await _refresh(force: true);
    _watch ??= Timer.periodic(const Duration(milliseconds: 250), (_) => unawaited(_refresh()));
  }

  Future<bool> _bindingsReady() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (DVNativeBridge.isRegistered('tray.show')) return true;
      if (attempt == 0) {
        await WidgetsBinding.instance.endOfFrame;
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    return DVNativeBridge.isRegistered('tray.show');
  }

  Future<bool> _readLaunchesOnLogin() async {
    final DVLaunchAtLogin login = DV.Platform.launchAtLogin;
    if (!login.isSupported) return PreferencesStore.state.launchesOnLogin;
    try {
      // The system's list is the truth: a user may have removed the login
      // item in the system settings.
      return await login.isEnabled();
    } on Object catch (error) {
      AppLog.warning('Unable to read the login item: $error');
      return PreferencesStore.state.launchesOnLogin;
    }
  }

  Future<void> _refresh({bool force = false}) async {
    final ProfilesState profiles = ProfileStore.state;
    final TunnelState tunnel = TunnelStore.state;
    final Preferences preferences = PreferencesStore.state;
    if (!force && identical(profiles, _profiles) && identical(tunnel, _tunnel) && identical(preferences, _preferences)) {
      return;
    }
    final bool keepsInMenuChanged = _preferences?.keepsInMenu != preferences.keepsInMenu;
    _profiles = profiles;
    _tunnel = tunnel;
    _preferences = preferences;
    final AppMenuModel model = AppMenuModel(
      profiles: profiles,
      tunnel: tunnel,
      preferences: preferences,
      launchesOnLogin: _launchesOnLogin,
    );
    _model = model;
    if (force || keepsInMenuChanged) {
      DVWindowManager.exitPolicy = preferences.keepsInMenu ? .explicit : .lastWindow;
    }
    try {
      if (!preferences.keepsInMenu) {
        if (_shown) await DV.Platform.tray.hide();
        _shown = false;
        return;
      }
      final TrayIcon icon = TrayIcon.of(appMenuImage(tunnel), template: _isMac);
      final String tooltip = appMenuTooltip(profiles, tunnel);
      final List<DVTrayMenuItem> menu = buildAppMenu(model);
      if (_shown) {
        // In place: the icon swaps between connected and disconnected
        // without leaving the tray.
        await DV.Platform.tray.update(icon: icon, tooltip: tooltip, menu: menu);
      } else {
        await DV.Platform.tray.show(
          icon: icon,
          template: _isMac,
          tooltip: tooltip,
          menu: menu,
          onSelected: _onSelected,
          // Windows and Linux: a click on the icon shows the window, the
          // menu is on a right-click. A macOS status item always opens it.
          onActivate: _isMac ? null : () => unawaited(_show()),
        );
        _shown = true;
      }
    } on Object catch (error) {
      // No tray binding (a Linux session with no bus) or a refusal: the
      // app runs without one, as upstream does when the extra is off.
      AppLog.warning('Unable to show the menu-bar icon: $error');
      _watch?.cancel();
      _watch = null;
      DVWindowManager.exitPolicy = .lastWindow;
    }
  }

  void _onSelected(String id) {
    final AppMenuModel? model = _model;
    if (model == null) return;
    unawaited(handleAppMenuSelection(id, model, AppMenuActions(
      show: _show,
      setLaunchesOnLogin: _setLaunchesOnLogin,
      setKeepsInMenu: (bool enabled) => PreferencesStore.update((Preferences p) => p.copyWith(keepsInMenu: enabled)),
      reconnect: TunnelStore.reconnect,
      disconnect: TunnelStore.disconnect,
      connect: TunnelStore.connect,
      about: () async {
        // openAbout: show the app, then the about panel.
        await _show();
        DV.Navigation.navigate(DVRoutes.settingsabout);
      },
      quit: _quit,
    )));
  }

  Future<void> _show() async {
    try {
      await DV.Platform.window.show();
    } on Object catch (error) {
      AppLog.error('Unable to launch app: $error');
    }
  }

  Future<void> _setLaunchesOnLogin(bool enabled) async {
    final DVLaunchAtLogin login = DV.Platform.launchAtLogin;
    if (login.isSupported) await login.setEnabled(enabled);
    await PreferencesStore.update((Preferences p) => p.copyWith(launchesOnLogin: enabled));
    _launchesOnLogin = enabled;
    await _refresh(force: true);
  }

  /// NSApp.terminate. The tunnel runs in this process here, unlike
  /// upstream's network extension, so it is disconnected first rather than
  /// cut off with the process.
  Future<void> _quit() async {
    _watch?.cancel();
    _watch = null;
    try {
      await TunnelStore.disconnect().timeout(const Duration(seconds: 5));
    } on Object catch (error) {
      AppLog.warning('Quitting with the tunnel still up: $error');
    }
    try {
      await DV.Platform.tray.hide();
    } on Object {
      // Leaving anyway.
    }
    await ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}
