// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The contract every module editor follows (upstream `ModuleViewFactory`).
// A module view gets the draft's current module and reports each edit with
// [ModuleViewArgs.onChanged]; the module page writes it into the draft.
//
// A module's sub-pages (a peer key, the remotes list, a certificate) are
// routes of their own, `/profiles/<id>/modules/<moduleId>/<section>`, so each
// has a URL and survives a reload. A view opens one with [pushModuleSection]
// and draws it in its [ModuleSubpage] function.

import 'package:flutter/widgets.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';

class const ModuleViewArgs({
  required final String profileId,
  required final TaggedModule module,
  required final ValueChanged<TaggedModule> onChanged,
});

/// Returns the sections (PSSection widgets) of a module's form.
typedef ModuleSections = List<Widget> Function(BuildContext context, ModuleViewArgs args);

/// Returns the page for [section] of a module, or null when the module has no
/// such section (the URL is stale or mistyped).
typedef ModuleSubpage = Widget? Function(BuildContext context, ModuleViewArgs args, String section);

/// The URL of [section] of the module in [args].
DVRouteTarget moduleSectionTarget(ModuleViewArgs args, String section) =>
    DVRoutes.profilesmodulesIdModuleIdSection(id: args.profileId, moduleId: args.module.id, section: section);

/// The module page's URL, where a sub-page goes back to.
DVRouteTarget moduleTarget(String profileId, String moduleId) =>
    DVRoutes.profilesmodules(id: profileId, moduleId: moduleId);

/// Opens [section] of the module in [args] over the module page.
void pushModuleSection(ModuleViewArgs args, String section) {
  DV.Navigation.push<void>(moduleSectionTarget(args, section));
}
