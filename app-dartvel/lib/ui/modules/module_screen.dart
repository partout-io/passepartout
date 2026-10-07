// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// /profiles/<id>/modules/<moduleId>: one module of the profile draft
// (upstream `ModuleDetailView` + `DefaultModuleViewFactory`).

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../../state/profile_draft.dart';
import '../kit.dart';
import 'dns_view.dart';
import 'http_proxy_view.dart';
import 'ip_view.dart';
import 'module_view.dart';
import 'on_demand_view.dart';
import 'openvpn_view.dart';
import 'wireguard_view.dart';

ModuleSections? moduleSectionsFor(String type) => switch (type) {
      ModuleType.dns => dnsSections,
      ModuleType.httpProxy => httpProxySections,
      ModuleType.ip => ipSections,
      ModuleType.onDemand => onDemandSections,
      ModuleType.openVPN => openVPNSections,
      ModuleType.wireGuard => wireGuardSections,
      _ => null,
    };

class const ModuleScreen({super.key, required final String profileId, required final String moduleId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Rebuild when profiles load (deep link) and on every draft edit.
    final profiles = context.global<ProfilesState>();
    final draft = context.global<ProfileDraft>();
    var profile = draft.profile?.id == profileId ? draft.profile : null;
    if (profile == null && profiles.isReady) {
      profile = DraftStore.open(profileId);
    }
    if (!profiles.isReady && profile == null) {
      return const PSScaffold(title: '', body: Center(child: CircularProgressIndicator.adaptive()));
    }
    final module = profile?.module(moduleId);
    if (profile == null || module == null) {
      return PSScaffold(title: tr(Strings.globalNounsModules), body: PSEmptyMessage(text: tr(Strings.globalNounsNoContent)));
    }
    final sections = moduleSectionsFor(module.type);
    final args = ModuleViewArgs(profileId: profileId, module: module, onChanged: DraftStore.saveModule);
    return PSScaffold(
      title: module.typeLabel,
      body: PSForm(children: <Widget>[
        PSSection(children: <Widget>[
          PSToggleRow(
            title: tr(Strings.globalNounsEnabled),
            value: profile.isActive(moduleId),
            onChanged: (_) => DraftStore.update((p) => p.togglingModule(moduleId)),
          ),
        ]),
        if (sections == null)
          PSSection(children: <Widget>[PSRow(title: module.typeLabel, subtitle: tr(Strings.globalNounsUnknown))])
        else
          ...sections(context, args),
      ]),
    );
  }
}
