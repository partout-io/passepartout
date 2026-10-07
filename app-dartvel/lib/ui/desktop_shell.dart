// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Desktop menu bar / tray (upstream `AppMenu`, macOS): connect or disconnect
// the profiles from the tray, show the window, quit; keep running in the
// tray after the window closes when "Keep in menu bar" is on.
//
// OWNER: tray workstream. This stub keeps the app building until it lands.

abstract final class DesktopShell {
  static Future<void> start() async {}
}
