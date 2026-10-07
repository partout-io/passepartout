// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Shared widget-test setup: translations loaded and DV.global state reset,
// in main.dart's order, so `tr()` returns English rather than raw keys.

import 'package:flutter/material.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/l10n/strings.g.dart';
import 'package:passepartout/state/app_log.dart';
import 'package:passepartout/state/app_state.dart';
import 'package:passepartout/state/profile_draft.dart';
import 'package:passepartout/ui/kit.dart';

void setUpApp() {
  const DVI18n().loadAll(stringCatalogs.values);
  const DVI18n().useLocale(const LocaleTag('en'));
  AppLog.init();
  ProfileStore.init();
  TunnelStore.init();
  PreferencesStore.init();
  DraftStore.init();
}

/// [child] inside the app theme, as a screen.
Widget appUnderTest(Widget child, {Brightness brightness = .light}) =>
    MaterialApp(theme: passepartoutTheme(brightness), home: child);
