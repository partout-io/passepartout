// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Desktop menu bar / tray (upstream `AppMenu`, macOS): connect or disconnect
// the profiles from the tray, show the window, quit; keep running in the
// tray after the window closes when "Keep in menu bar" is on.
//
// The menu is in desktop/app_menu.dart and the tray in
// desktop/tray_controller.dart. A no-op on the web and on mobile.

import 'desktop/tray_controller.dart';

abstract final class DesktopShell {
  static Future<void> start() => TrayController.instance.start();
}
