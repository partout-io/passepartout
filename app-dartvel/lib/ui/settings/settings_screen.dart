// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `SettingsCoordinator` + `SettingsContentView` (iOS and macOS).
//
// Rows, in upstream order. iOS (phones, tablets, web):
//   [Preferences, Version, VersionUpdateLink]
//   About: [Links, Credits, (Donate: IAP only)]
//   Troubleshooting: [FAQ]
//   [Diagnostics, (Purchased: IAP only)]
// macOS (desktop builds):
//   [Preferences, VersionUpdateLink]
//   About: [Version, Links, Credits, (Donate)]
//   Troubleshooting: [FAQ, (System extension), Diagnostics, (Purchased)]
//   and the version string under the list.
//
// This app has no in-app purchases (upstream's `supportsIAP` is App Store
// only), so Donate and Purchased are left out as upstream leaves them out
// off the App Store; the web donation link is in Links, as upstream shows it.

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../l10n/strings.g.dart';
import '../kit.dart';
import 'settings_support.dart';

class const SettingsScreen({super.key, final bool? desktopLayout}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final desktop = desktopLayout ?? isDesktopPlatform;
    final preferences = PSRow(
      title: tr(Strings.globalNounsPreferences),
      navigates: true,
      onTap: () => pushRoute(DVRoutes.settingspreferences),
    );
    final version = PSRow(
      title: tr(Strings.globalNounsVersion),
      // `themeTrailingValue(versionString)` is iOS only.
      value: desktop ? null : SettingsBundle.versionString,
      navigates: true,
      onTap: () => pushRoute(DVRoutes.settingsversion),
    );
    final links = PSRow(
      title: tr(Strings.viewsSettingsLinksTitle),
      navigates: true,
      onTap: () => pushRoute(DVRoutes.settingsabout),
    );
    final credits = PSRow(
      title: tr(Strings.viewsSettingsCreditsTitle),
      navigates: true,
      onTap: () => pushRoute(DVRoutes.settingsaboutcredits),
    );
    const faq = SettingsLinkRow(title: SettingsUnlocalized.faq, url: SettingsConstants.faqUrl);
    final diagnostics = PSRow(
      title: tr(Strings.viewsDiagnosticsTitle),
      navigates: true,
      onTap: () => pushRoute(DVRoutes.settingsdiagnostics),
    );
    // `VersionUpdateLink` shows a row only once the version checker found a
    // newer release; this port has no version checker yet, so it is empty.
    final sections = desktop
        ? <Widget>[
            PSSection(children: <Widget>[preferences]),
            PSSection(header: tr(Strings.globalNounsAbout), children: <Widget>[version, links, credits]),
            PSSection(header: tr(Strings.globalNounsTroubleshooting), children: <Widget>[faq, diagnostics]),
            Padding(
              padding: const .all(16),
              child: Text(SettingsBundle.versionString, textAlign: .center),
            ),
          ]
        : <Widget>[
            PSSection(children: <Widget>[preferences, version]),
            PSSection(header: tr(Strings.globalNounsAbout), children: <Widget>[links, credits]),
            PSSection(header: tr(Strings.globalNounsTroubleshooting), children: const <Widget>[faq]),
            PSSection(children: <Widget>[diagnostics]),
          ];
    return PSScaffold(
      // iOS: `Strings.Global.Nouns.settings`; macOS: `Strings.Views.Settings.title`.
      title: desktop ? tr(Strings.viewsSettingsTitle) : tr(Strings.globalNounsSettings),
      body: PSForm(children: sections),
    );
  }
}
