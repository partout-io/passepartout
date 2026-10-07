# PROGRESS: pp-tray-app (branch agent/pp-tray-app)

## Done

- `app-dartvel/lib/ui/desktop/app_menu.dart`: upstream `AppMenu.body` 1:1 as a pure function --
  version line (header), Show, Launch on login (check), Keep in menu bar (check), Reconnect and
  Disconnect (enabled only while connecting/connected), the profiles under the default folder name
  (header) with a check on every non-disconnected profile, About, "Quit Passepartout"
  (`tr(Strings.viewsAppMenuItemsQuit, ['Passepartout'])`). `AppMenuImage` 1:1 (error -> inactive,
  connected -> active, connecting/disconnecting -> pending). Upstream's MenuActive/Inactive/Pending
  template PNGs in `assets/tray/`, plus white copies for Windows/Linux.
- `app-dartvel/lib/ui/desktop/tray_controller.dart`: shows the tray on macOS/Windows/Linux only
  (no-op on web/mobile), honours `Preferences.keepsInMenu` (on: tray shown and
  `DVWindowManager.exitPolicy = .explicit`, so closing the window hides it; off: tray hidden,
  exitPolicy lastWindow, as upstream's `applicationShouldTerminateAfterLastWindowClosed`).
  Selecting a profile toggles connect/disconnect through `TunnelStore`; Show ->
  `DV.Platform.window.show()`; About -> show + `DV.Navigation.navigate(DVRoutes.settingsabout)`;
  launch on login -> `DV.Platform.launchAtLogin` + `Preferences.launchesOnLogin`; Quit disconnects
  the in-process tunnel (5 s timeout) then `exitApplication`. Windows/Linux left-click shows the
  window. The icon/tooltip/menu change in place with `DV.Platform.tray.update`.
- Rebuild on state change: DV.global has no listener outside widgets and the tray must follow the
  tunnel while the window is hidden (no frames), so a 250 ms timer compares ProfilesState,
  TunnelState and Preferences by identity (stores replace them) and redraws only on change.
- `desktop_shell.dart` calls `TrayController.instance.start()`; start waits for the platform
  bindings (they are registered on the router's first build, which can come after main() calls
  DesktopShell.start).
- Commit 2a8d7a55f.

## Tests

- `test/tray_app_menu_test.dart`: 19 tests (order, headers, strings, toggles, enabled logic per
  status, active checks, framework accepts the menu, icon per status, icon files exist, action
  routing, failures logged). Pass.
- `dart analyze lib`: 0 errors.
- `~/heavy.sh flutter build linux`: passes (after `dartvel build linux` generated the ephemeral
  linux/ folder; LD_LIBRARY_PATH must NOT be set for the build -- cmake breaks on the custom openssl).
- Built Linux app run under `dbus-run-session` + `xvfb-run` with a stand-in StatusNotifierWatcher:
  the item registered (`org.kde.StatusNotifierItem-<pid>-1`), Title "Passepartout: Inactive",
  IconThemePath = bundle's flutter_assets/assets/tray with menu_inactive_light.png present,
  ItemIsMenu false, and the menu read over dbusmenu:
  version (disabled) / --- / Show / [ ] Launch on login / [x] Keep in menu bar / --- /
  Reconnect (disabled) / Disconnect (disabled) / --- / About / Quit Passepartout.
  Activate and a click on Show were accepted. (No profiles in the temp data dir.)
- `test/widget_test.dart` and `test/engine_test.dart` fail on this branch with and without this
  change (engine_test does not compile against the current domain code) -- not this workstream.

## Local-only changes (NOT committed, reverted after testing)

- pubspec.yaml: dartvel_* paths pointed at `/home/sigmadev/wt/dv-tray-menus/packages/...` and
  `- assets/tray/` added to flutter.assets; pubspec.lock followed. Both restored.
- `dartvel build linux` adds `linux/**` to analysis_options.yaml; restored.

## Requests to lead

1. Merge Dartvel `feat/tray-menus` first: this code uses `DVTrayMenuItem.header/.separator`,
   `checked`, `DVTray.update`, `show(template:, onActivate:)`, `DV.Platform.window.show()`,
   `DV.Platform.launchAtLogin`, `DVWindowManager.exitPolicy` setter use. It does not compile
   against current dartvel_dev main.
2. Add `- assets/tray/` under `flutter: assets:` in app-dartvel/pubspec.yaml. Without it the icons
   are not bundled (the tray falls back to a theme name / title text). `TrayIcon` implements
   DVAssetRef by hand for that reason; it can switch to generated `DVAsset.menuActive...` after.
3. Consider calling `DesktopShell.start()` after the first frame in main.dart; the controller
   waits for the bindings itself, so this is optional.

## Dartvel gaps (for app-dartvel/docs/DARTVEL-GAPS.md; not written there to avoid an add/add
conflict, the file does not exist on this branch)

- Tray workstream: no way to observe a `DV.global<T>` value outside a widget. Repro: in
  `main()`, after `runApp`, react to `TunnelStore` replacing `TunnelState` while the window is
  hidden -- only a timer works.
- Tray workstream: no API for the app's version/build (upstream `bundle.versionString`);
  `appVersionString` is hand-kept in app_menu.dart.

## Not verified

- macOS and Windows: compiled (analyze) only. The macOS menu is a status item whose click opens
  the menu (no onActivate there), as upstream.
- Close-to-hide in the built app (no window manager in Xvfb to send a close); the framework hook
  itself is verified against real GTK in the Dartvel suite.
- Upstream's `updateButton` (VersionUpdateLink) is omitted: no update checker in this app.
