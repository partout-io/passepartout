// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// The profile being edited (upstream `ProfileEditor`). Edits from the profile
// page and every module page go to this draft; nothing reaches disk until
// "Save". A module page opened by deep link starts the draft from disk.

import '../dartvel_client/dartvel_client.dart';
import '../domain/profile.dart';
import 'app_state.dart';

class const ProfileDraft({final TunnelProfile? profile, final bool isNew = false, final bool isDirty = false});

abstract final class DraftStore {
  static ProfileDraft get state => DV.global<ProfileDraft>();
  static void init() => DV.global<ProfileDraft>(const ProfileDraft());

  /// Starts editing [profileId] unless the draft already holds it.
  static TunnelProfile? open(String profileId) {
    final current = state.profile;
    if (current != null && current.id == profileId) return current;
    final stored = ProfileStore.state.byId(profileId);
    DV.global<ProfileDraft>(ProfileDraft(profile: stored));
    return stored;
  }

  /// Starts a brand-new profile ("Empty profile").
  static TunnelProfile create(String name) {
    final profile = TunnelProfile.empty(name);
    DV.global<ProfileDraft>(ProfileDraft(profile: profile, isNew: true, isDirty: true));
    return profile;
  }

  static void update(TunnelProfile Function(TunnelProfile) change) {
    final current = state;
    if (current.profile == null) return;
    DV.global<ProfileDraft>(ProfileDraft(profile: change(current.profile!), isNew: current.isNew, isDirty: true));
  }

  /// Replaces one module in the draft (what each module page calls on edit).
  static void saveModule(TaggedModule module) => update((profile) => profile.savingModule(module, activate: false));

  static Future<TunnelProfile?> commit() async {
    final profile = state.profile;
    if (profile == null) return null;
    await ProfileStore.save(profile);
    DV.global<ProfileDraft>(ProfileDraft(profile: profile));
    return profile;
  }

  static void discard() => DV.global<ProfileDraft>(const ProfileDraft());
}
