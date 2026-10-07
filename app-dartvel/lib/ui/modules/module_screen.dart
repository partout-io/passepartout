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

ModuleSubpage? moduleSubpageFor(String type) => switch (type) {
      ModuleType.openVPN => openVPNSubpage,
      ModuleType.wireGuard => wireGuardSubpage,
      _ => null,
    };

/// The draft's profile and module for a module URL, opening the draft from
/// disk on a deep link; or, in [instead], the page to show while profiles load
/// or when the module does not exist.
({TunnelProfile? profile, TaggedModule? module, Widget? instead}) _resolve(BuildContext context, String profileId, String moduleId) {
  // Rebuild when profiles load (deep link) and on every draft edit.
  final profiles = context.global<ProfilesState>();
  final draft = context.global<ProfileDraft>();
  var profile = draft.profile?.id == profileId ? draft.profile : null;
  if (profile == null && profiles.isReady) {
    profile = DraftStore.open(profileId);
  }
  if (!profiles.isReady && profile == null) {
    return (profile: null, module: null, instead: const PSScaffold(title: '', body: Center(child: CircularProgressIndicator.adaptive())));
  }
  final module = profile?.module(moduleId);
  if (profile == null || module == null) {
    return (
      profile: null,
      module: null,
      instead: PSScaffold(title: tr(Strings.globalNounsModules), body: PSEmptyMessage(text: tr(Strings.globalNounsNoContent))),
    );
  }
  return (profile: profile, module: module, instead: null);
}

class const ModuleScreen({super.key, required final String profileId, required final String moduleId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (:profile, :module, :instead) = _resolve(context, profileId, moduleId);
    if (profile == null || module == null) return instead!;
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

/// /profiles/<id>/modules/<moduleId>/<section>: one sub-page of a module
/// (a peer key, the remotes, a certificate). Reads the module from the draft
/// like [ModuleScreen], so it works after a reload, and saves edits to it.
/// Back goes to the module page, also when the page was opened by URL.
class const ModuleSectionScreen({
  super.key,
  required final String profileId,
  required final String moduleId,
  required final String section,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (profile: _, :module, :instead) = _resolve(context, profileId, moduleId);
    if (module == null) return instead!;
    final args = ModuleViewArgs(profileId: profileId, module: module, onChanged: DraftStore.saveModule);
    final page = moduleSubpageFor(module.type)?.call(context, args, section) ??
        PSScaffold(title: module.typeLabel, body: PSEmptyMessage(text: tr(Strings.globalNounsNoContent)));
    return PSBackTarget(target: moduleTarget(profileId, moduleId), child: page);
  }
}
