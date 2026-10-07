// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The contract every module editor follows (upstream `ModuleViewFactory`).
// A module view gets the draft's current module and reports each edit with
// [ModuleViewArgs.onChanged]; the module page writes it into the draft.

import 'package:flutter/widgets.dart';

import '../../domain/profile.dart';

class const ModuleViewArgs({
  required final String profileId,
  required final TaggedModule module,
  required final ValueChanged<TaggedModule> onChanged,
});

/// Returns the sections (PSSection widgets) of a module's form.
typedef ModuleSections = List<Widget> Function(BuildContext context, ModuleViewArgs args);
