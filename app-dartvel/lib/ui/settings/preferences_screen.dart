// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `PreferencesView` (AppLibrary/Views/Preferences), row for row:
//
//   System appearance picker
//   iOS:   Lock in background            -> omitted: Apple-only (Face ID lock)
//   macOS: Launch on login, Keep in menu -> desktop builds here
//   Pin active profile
//   DNS falls back
//   Enable purchases (supportsIAP)       -> omitted: Apple-only (in-app purchases)
//   Crypto backend (beta builds only)    -> omitted: no beta channel, no preference yet
//   Erase iCloud (supportsCloudKit)      -> omitted: Apple-only (iCloud)
//   Advanced (config flags)              -> omitted: Android hides it too, no flags
//
// Each toggle sits in its own section with its footer as subtitle, which is
// what `themeContainerEntry(subtitle:)` draws.

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../kit.dart';
import 'settings_support.dart';

class const PreferencesScreen({super.key, final bool? desktopLayout}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferences = context.global<Preferences>();
    final desktop = desktopLayout ?? isDesktopPlatform;
    void update(Preferences Function(Preferences) change) =>
        runGuarded(context, () => PreferencesStore.update(change));

    return PSScaffold(
      title: tr(Strings.globalNounsPreferences),
      body: PSForm(children: <Widget>[
        PSSection(children: <Widget>[
          PSPickerRow<SystemAppearance>(
            title: tr(Strings.viewsPreferencesSystemAppearance),
            value: preferences.appearance,
            options: SystemAppearance.values,
            label: systemAppearanceLabel,
            onChanged: (value) => update((current) => current.copyWith(appearance: value)),
          ),
        ]),
        if (desktop) ...<Widget>[
          PSSection(
            footer: tr(Strings.viewsPreferencesLaunchesOnLoginFooter),
            children: <Widget>[
              PSToggleRow(
                title: tr(Strings.viewsPreferencesLaunchesOnLogin),
                value: preferences.launchesOnLogin,
                onChanged: (value) => update((current) => current.copyWith(launchesOnLogin: value)),
              ),
            ],
          ),
          PSSection(
            footer: tr(Strings.viewsPreferencesKeepsInMenuFooter),
            children: <Widget>[
              PSToggleRow(
                title: tr(Strings.viewsPreferencesKeepsInMenu),
                value: preferences.keepsInMenu,
                onChanged: (value) => update((current) => current.copyWith(keepsInMenu: value)),
              ),
            ],
          ),
        ],
        PSSection(
          footer: tr(Strings.viewsPreferencesPinsActiveProfileFooter),
          children: <Widget>[
            PSToggleRow(
              title: tr(Strings.viewsPreferencesPinsActiveProfile),
              value: preferences.pinsActiveProfile,
              onChanged: (value) => update((current) => current.copyWith(pinsActiveProfile: value)),
            ),
          ],
        ),
        PSSection(
          footer: tr(Strings.viewsPreferencesDnsFallsBackFooter),
          children: <Widget>[
            PSToggleRow(
              title: tr(Strings.viewsPreferencesDnsFallsBack),
              value: preferences.dnsFallsBack,
              onChanged: (value) => update((current) => current.copyWith(dnsFallsBack: value)),
            ),
          ],
        ),
      ]),
    );
  }
}

/// `SystemAppearance?.localizedDescription`, nil being "System".
String systemAppearanceLabel(SystemAppearance appearance) => switch (appearance) {
      .system => tr(Strings.entitiesUiSystemAppearanceSystem),
      .light => tr(Strings.entitiesUiSystemAppearanceLight),
      .dark => tr(Strings.entitiesUiSystemAppearanceDark),
    };
