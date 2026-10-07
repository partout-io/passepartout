// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// "/profiles/<id>": edit a profile (upstream `ProfileCoordinator`,
// `ProfileEditView` iOS / `ProfileSplitView` macOS, `ProfileNameSection`,
// modules section with `EditorModuleToggle`, `AddModuleMenu`,
// `ProfileBehaviorSection`, `ProfileActionsSection`, `ProfileSaveButton`).
//
// Omitted, Apple-only: iCloud sharing, "Send to TV", Shortcuts, paywall.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../../state/profile_draft.dart';
import '../kit.dart';

bool get _isApple => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  Set<String> _errorModuleIds = <String>{};
  bool _saving = false;

  Future<void> _save(TunnelProfile profile) async {
    final problem = profile.validate();
    if (problem != null) {
      setState(() => _errorModuleIds = problem.moduleIds);
      await showErrorAlert(context, title: profile.name, message: _message(problem));
      return;
    }
    setState(() {
      _saving = true;
      _errorModuleIds = <String>{};
    });
    await runGuarded(context, () async {
      await DraftStore.commit();
      DraftStore.discard();
      _close();
    });
    if (mounted) setState(() => _saving = false);
  }

  String _message(ProfileProblem problem) => switch (problem.kind) {
        .emptyName => tr(Strings.errorsAppEmptyProfileName),
        .noActiveModules => tr(Strings.errorsAppNoActiveModules),
        .incompatibleModules => tr(Strings.errorsAppIncompatibleModules),
        .incompleteModule => tr(Strings.errorsAppIncompleteModule, <Object>[problem.moduleType ?? '']),
      };

  void _cancel() {
    DraftStore.discard();
    _close();
  }

  void _close() {
    if (DV.Navigation.canGoBack) {
      DV.Navigation.back();
    } else {
      DV.Navigation.navigate(DVRoutes.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.global<ProfilesState>();
    final draft = context.global<ProfileDraft>();
    var profile = draft.profile?.id == widget.profileId ? draft.profile : null;
    if (profile == null && profiles.isReady) profile = DraftStore.open(widget.profileId);
    if (profile == null) {
      return PSScaffold(
        title: tr(Strings.globalNounsProfile),
        body: profiles.isReady
            ? PSEmptyMessage(text: tr(Strings.globalNounsNoContent))
            : const Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final current = profile;
    final isExisting = profiles.byId(current.id) != null;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _save(current),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => _save(current),
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) DraftStore.discard();
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leadingWidth: 96,
            leading: TextButton(onPressed: _cancel, child: Text(tr(Strings.globalActionsCancel))),
            title: Semantics(headingLevel: 1, child: Text(tr(Strings.globalNounsProfile))),
            centerTitle: true,
            actions: <Widget>[
              if (_saving)
                const Padding(padding: .all(14), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else
                TextButton(
                  onPressed: () => _save(current),
                  child: Text(tr(Strings.globalActionsSave), style: const TextStyle(fontWeight: .w600)),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: PSForm(children: <Widget>[
              PSSection(
                header: tr(Strings.globalNounsName),
                footer: _isApple ? tr(Strings.viewsProfileSectionsNameFooter) : null,
                children: <Widget>[
                  _NameField(
                    name: current.name,
                    onSubmitted: () => _save(DraftStore.state.profile ?? current),
                  ),
                ],
              ),
              _ModulesSection(profile: current, errorModuleIds: _errorModuleIds),
              PSSection(
                header: tr(Strings.modulesGeneralSectionsBehaviorHeader),
                children: <Widget>[
                  PSToggleRow(
                    title: tr(Strings.modulesGeneralRowsKeepAliveOnSleep),
                    subtitle: tr(Strings.modulesGeneralRowsKeepAliveOnSleepFooter),
                    value: !current.disconnectsOnSleep,
                    onChanged: (on) => DraftStore.update((p) => p.withBehavior(disconnectsOnSleep: !on)),
                  ),
                  PSToggleRow(
                    title: tr(Strings.modulesGeneralRowsEnforceTunnel),
                    subtitle: tr(Strings.modulesGeneralRowsEnforceTunnelFooter),
                    value: current.includesAllNetworks,
                    onChanged: (on) => DraftStore.update((p) => p.withBehavior(includesAllNetworks: on)),
                  ),
                ],
              ),
              PSSection(children: <Widget>[
                PSRow(
                  title: 'ID',
                  subtitle: current.id,
                  monospaced: true,
                  selectable: true,
                  trailing: IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => copyToClipboard(context, current.id),
                  ),
                ),
              ]),
              if (isExisting)
                PSSection(children: <Widget>[
                  PSRow(
                    title: tr(Strings.viewsProfileRowsDeleteProfile),
                    destructive: true,
                    onTap: () async {
                      final confirmed = await confirmDestructive(
                        context,
                        title: tr(Strings.globalActionsDelete),
                        message: current.name,
                        action: tr(Strings.globalActionsDelete),
                      );
                      if (!confirmed) return;
                      DraftStore.discard();
                      _close();
                      await ProfileStore.remove(current.id);
                    },
                  ),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.name, required this.onSubmitted});

  final String name;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => PSTextRow(
        label: tr(Strings.globalNounsName),
        value: name,
        placeholder: tr(Strings.placeholdersProfileName),
        onChanged: (text) => DraftStore.update((p) => p.renamed(text)),
        onSubmitted: (_) => onSubmitted(),
      );
}

/// Modules: a switch per module (tap the name to edit it), drag to reorder,
/// swipe to delete, then "Add module".
class const _ModulesSection({required final TunnelProfile profile, required final Set<String> errorModuleIds}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modules = profile.modules;
    final theme = Theme.of(context);
    final present = modules.map((m) => m.type).toSet();
    final available = ModuleType.addable.where((t) => !present.contains(t)).toList();
    return PSSection(
      header: tr(Strings.globalNounsModules),
      footer: tr(Strings.viewsProfileModuleListSectionFooter),
      children: <Widget>[
        if (modules.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => DraftStore.update((p) => p.movingModule(from, to > from ? to + 1 : to)),
            children: <Widget>[
              for (var i = 0; i < modules.length; i++)
                Dismissible(
                  key: ValueKey<String>(modules[i].id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: PSColors.error,
                    alignment: Alignment.centerRight,
                    padding: const .only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => DraftStore.update((p) => p.removingModule(modules[i].id)),
                  child: Material(
                    color: theme.colorScheme.surface,
                    child: Column(mainAxisSize: .min, children: <Widget>[
                      if (i > 0) const Padding(padding: .only(left: 16), child: Divider()),
                      _ModuleRow(
                        index: i,
                        profile: profile,
                        module: modules[i],
                        hasError: errorModuleIds.contains(modules[i].id),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        _AddModuleMenu(types: available, profileId: profile.id),
      ],
    );
  }
}

class const _ModuleRow({
  required final int index,
  required final TunnelProfile profile,
  required final TaggedModule module,
  required final bool hasError,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const .only(left: 4, right: 8),
        leading: ReorderableDragStartListener(
          index: index,
          child: const Padding(padding: .all(8), child: Icon(Icons.drag_indicator, size: 20)),
        ),
        title: Row(children: <Widget>[
          Flexible(child: Text(module.typeLabel)),
          if (hasError) const Padding(padding: .only(left: 6), child: Icon(Icons.warning_amber, color: PSColors.pending, size: 18)),
          const Icon(Icons.chevron_right, size: 20),
        ]),
        onTap: () => DV.Navigation.push(DVRoutes.profilesmodules(id: profile.id, moduleId: module.id)),
        trailing: Switch.adaptive(
          value: profile.isActive(module.id),
          onChanged: (_) => DraftStore.update((p) => p.togglingModule(module.id)),
        ),
      );
}

/// `AddModuleMenu`: "Connection" types, then "Settings" types; disabled when none left.
class const _AddModuleMenu({required final List<String> types, required final String profileId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connection = types.where(ModuleType.isConnection).toList()..sort();
    final other = types.where((t) => !ModuleType.isConnection(t)).toList()..sort();
    Widget entry(String type) => MenuItemButton(
          onPressed: () {
            final module = TaggedModule.empty(type);
            DraftStore.update((p) => p.savingModule(module, activate: true));
            DV.Navigation.push(DVRoutes.profilesmodules(id: profileId, moduleId: module.id));
          },
          child: Text(TaggedModule.of(type, const <String, dynamic>{'id': ''}).typeLabel),
        );
    Widget header(String text) => Padding(
          padding: const .fromLTRB(12, 8, 12, 4),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall),
        );
    return MenuAnchor(
      menuChildren: <Widget>[
        if (connection.isNotEmpty) ...<Widget>[header(tr(Strings.globalNounsConnection)), ...connection.map(entry)],
        if (connection.isNotEmpty && other.isNotEmpty) const Divider(height: 1),
        if (other.isNotEmpty) ...<Widget>[header(tr(Strings.globalNounsSettings)), ...other.map(entry)],
      ],
      builder: (context, controller, _) => PSRow(
        title: tr(Strings.viewsProfileRowsAddModule),
        onTap: types.isEmpty ? null : () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
