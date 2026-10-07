// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The tray menu, ported from upstream `AppMenu` (macOS) and `AppMenuImage`:
// app-apple/Sources/AppLibraryMain/Views/AppMenu/macOS/AppMenu.swift.
//
// Pure: the menu and the icon are functions of the app state, so they are
// tested without a desktop, and the tray controller only shows what these
// return and routes what is chosen.

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../kit.dart';

/// Upstream `appConfiguration.bundle.displayName`.
const String appDisplayName = 'Passepartout';

/// Upstream `bundle.versionString`. Dartvel has no API for the running
/// app's version, so this follows pubspec.yaml by hand (see PROGRESS).
const String appVersionString = '$appDisplayName 0.0.1';

/// The ids of the menu's items. A profile's id is [profilePrefix] + its id.
abstract final class AppMenuIds {
  static const String version = 'version';
  static const String show = 'show';
  static const String launchesOnLogin = 'launchesOnLogin';
  static const String keepsInMenu = 'keepsInMenu';
  static const String reconnect = 'reconnect';
  static const String disconnect = 'disconnect';
  static const String profilesHeader = 'profiles';
  static const String profilePrefix = 'profile:';
  static const String about = 'about';
  static const String quit = 'quit';
}

/// Everything the menu shows.
class const AppMenuModel({
  required final ProfilesState profiles,
  required final TunnelState tunnel,
  required final Preferences preferences,
  required final bool launchesOnLogin,
});

/// Upstream `AppMenu.body`, item for item: version, show, the two toggles,
/// reconnect and disconnect (enabled only while connecting or connected),
/// the profiles under the default folder's name with the active one
/// checked, about and quit.
List<DVTrayMenuItem> buildAppMenu(AppMenuModel model) {
  // TODO(upstream #218): per tunnel. Upstream reads the first active
  // profile; this app has one active profile at most.
  final bool isTunnelActionable = model.tunnel.activeProfileId != null &&
      (model.tunnel.status == .connecting || model.tunnel.status == .connected);
  return <DVTrayMenuItem>[
    const DVTrayMenuItem.header(appVersionString, id: AppMenuIds.version),
    // updateButton: VersionUpdateLink shows nothing without an update
    // checker, which this app does not have.
    const DVTrayMenuItem.separator(),
    DVTrayMenuItem(id: AppMenuIds.show, label: tr(Strings.globalActionsShow)),
    DVTrayMenuItem(
      id: AppMenuIds.launchesOnLogin,
      label: tr(Strings.viewsPreferencesLaunchesOnLogin),
      checked: model.launchesOnLogin,
    ),
    DVTrayMenuItem(
      id: AppMenuIds.keepsInMenu,
      label: tr(Strings.viewsPreferencesKeepsInMenu),
      checked: model.preferences.keepsInMenu,
    ),
    const DVTrayMenuItem.separator(),
    DVTrayMenuItem(id: AppMenuIds.reconnect, label: tr(Strings.globalActionsReconnect), enabled: isTunnelActionable),
    DVTrayMenuItem(id: AppMenuIds.disconnect, label: tr(Strings.globalActionsDisconnect), enabled: isTunnelActionable),
    if (model.profiles.hasProfiles) ...<DVTrayMenuItem>[
      const DVTrayMenuItem.separator(),
      DVTrayMenuItem.header(tr(Strings.viewsAppFoldersDefault), id: AppMenuIds.profilesHeader),
      for (final profile in model.profiles.filtered)
        DVTrayMenuItem(
          id: '${AppMenuIds.profilePrefix}${profile.id}',
          label: profile.name,
          // isProfileActive: anything but disconnected.
          checked: model.tunnel.statusOf(profile.id) != .disconnected,
        ),
    ],
    const DVTrayMenuItem.separator(),
    DVTrayMenuItem(id: AppMenuIds.about, label: tr(Strings.globalNounsAbout)),
    DVTrayMenuItem(id: AppMenuIds.quit, label: tr(Strings.viewsAppMenuItemsQuit, <Object>[appDisplayName])),
  ];
}

/// Upstream `Theme.MenuImageName`.
enum AppMenuImage { active, inactive, pending }

/// Upstream `AppMenuImage.status`: an error shows as disconnected, then the
/// active profile's status picks the image.
AppMenuImage appMenuImage(TunnelState tunnel) {
  if (tunnel.lastErrorCode != null) return .inactive;
  final String? id = tunnel.activeProfileId;
  if (id == null) return .inactive;
  return switch (tunnel.statusOf(id)) {
    .connected => .active,
    .disconnected => .inactive,
    .connecting || .disconnecting => .pending,
  };
}

/// The tray icon files. macOS draws the black template images in the menu
/// bar's own colour; Windows and Linux get the white copies, since their
/// trays draw an image as it is and their panels are dark by default.
///
/// Implemented here rather than read from the generated `DVAsset`, because
/// `assets/tray/` is not listed in pubspec.yaml yet (a request to the
/// lead); `test/tray_app_menu_test.dart` checks every file exists, so a
/// rename still fails a build step.
enum TrayIcon implements DVAssetRef {
  active('assets/tray/menu_active.png'),
  inactive('assets/tray/menu_inactive.png'),
  pending('assets/tray/menu_pending.png'),
  activeLight('assets/tray/menu_active_light.png'),
  inactiveLight('assets/tray/menu_inactive_light.png'),
  pendingLight('assets/tray/menu_pending_light.png');

  const TrayIcon(this.path);

  @override
  final String path;

  @override
  DVAssetKind get kind => DVAssetKind.image;

  static TrayIcon of(AppMenuImage image, {required bool template}) => switch (image) {
        .active => template ? active : activeLight,
        .inactive => template ? inactive : inactiveLight,
        .pending => template ? pending : pendingLight,
      };
}

/// The tooltip: the active profile's status, as the profile list words it.
String appMenuTooltip(ProfilesState profiles, TunnelState tunnel) {
  final String? id = tunnel.activeProfileId;
  final String status = switch (id == null ? TunnelStatus.disconnected : tunnel.statusOf(id)) {
    .connected => tr(Strings.entitiesTunnelStatusActive),
    .connecting => tr(Strings.entitiesTunnelStatusActivating),
    .disconnecting => tr(Strings.entitiesTunnelStatusDeactivating),
    .disconnected => tr(Strings.entitiesTunnelStatusInactive),
  };
  final String? name = id == null ? null : profiles.byId(id)?.name;
  return name == null ? '$appDisplayName: $status' : '$appDisplayName: $name, $status';
}
