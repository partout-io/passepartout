// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// "/": the profile list (upstream `AppCoordinator` + `ProfileContainerView`,
// `ProfileListView`, `ProfileGridView`, `InstalledProfileView`,
// `ProfileRowView`, `ProfileCardView`, `ProfileContextMenu`, `AppToolbar`,
// `AddProfileMenu`, `ProfilesLayoutPicker`).

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../dartvel_client/dartvel_client.dart';
import '../../domain/profile.dart';
import '../../l10n/strings.g.dart';
import '../../state/app_state.dart';
import '../../state/profile_draft.dart';
import '../kit.dart';

/// `isBigDevice`: iPad/Mac layout (toolbar group, grid available).
bool isBigLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= 700;

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = context.global<ProfilesState>();
    final preferences = context.global<Preferences>();
    final big = isBigLayout(context);
    final layout = big ? preferences.layout : ProfilesLayout.list;
    final searching = profiles.search.trim().isNotEmpty;

    final Widget body;
    if (!profiles.isReady) {
      body = Center(child: CircularProgressIndicator.adaptive(semanticsLabel: tr(Strings.globalNounsLoading)));
    } else if (!profiles.hasProfiles) {
      body = PSEmptyMessage(text: tr(Strings.viewsAppFoldersNoProfiles));
    } else {
      final header = preferences.pinsActiveProfile && !searching ? const InstalledProfileHeader() : null;
      body = layout == .grid
          ? _ProfileGrid(header: header, profiles: profiles.filtered)
          : _ProfileList(header: header, profiles: profiles.filtered);
    }

    return Scaffold(
      appBar: AppBar(
        leading: big ? null : const _SettingsButton(),
        title: const Text('Passepartout'),
        actions: <Widget>[
          if (profiles.hasProfiles) _SearchField(controller: _search),
          const AddProfileMenu(),
          if (big) ...<Widget>[
            const _SettingsButton(),
            _LayoutPicker(layout: preferences.layout),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class const _SettingsButton() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tr(Strings.globalNounsSettings),
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => DV.Navigation.push(DVRoutes.settings),
      );
}

class const _LayoutPicker({required final ProfilesLayout layout}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SegmentedButton<ProfilesLayout>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const <ButtonSegment<ProfilesLayout>>[
          ButtonSegment<ProfilesLayout>(value: .list, icon: Icon(Icons.view_list_outlined, semanticLabel: 'List')),
          ButtonSegment<ProfilesLayout>(value: .grid, icon: Icon(Icons.grid_view_outlined, semanticLabel: 'Grid')),
        ],
        selected: <ProfilesLayout>{layout},
        onSelectionChanged: (selection) => PreferencesStore.update((p) => p.copyWith(layout: selection.first)),
      );
}

/// `.searchable(text:)`: filters profiles by name.
class const _SearchField({required final TextEditingController controller}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isBigLayout(context) ? 220 : 140),
        child: Padding(
          padding: const .symmetric(vertical: 8),
          child: TextField(
            controller: controller,
            onChanged: ProfileStore.search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              border: OutlineInputBorder(borderRadius: .circular(10), borderSide: BorderSide.none),
              contentPadding: const .symmetric(vertical: 8),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Add profile

class const AddProfileMenu() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MenuAnchor(
        menuChildren: <Widget>[
          MenuItemButton(
            leadingIcon: const Icon(Icons.edit_outlined),
            onPressed: () => newEmptyProfile(context),
            child: Text(tr(Strings.viewsAppToolbarNewProfileEmpty)),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.file_open_outlined),
            onPressed: () => importProfileFile(context),
            child: Text('${tr(Strings.viewsAppToolbarImportFile)}...'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.text_snippet_outlined),
            onPressed: () => DV.Navigation.push(DVRoutes.importtext),
            child: Text('${tr(Strings.viewsAppToolbarImportTextTitle)}...'),
          ),
        ],
        builder: (context, controller, _) => IconButton(
          tooltip: tr(Strings.globalActionsAdd),
          icon: const Icon(Icons.add),
          onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        ),
      );
}

void newEmptyProfile(BuildContext context) {
  final profile = DraftStore.create(ProfileStore.state.firstUniqueName(tr(Strings.placeholdersProfileName)));
  DV.Navigation.push(DVRoutes.profiles(id: profile.id));
}

/// `ProfileImporterModifier`: pick .ovpn/.conf files and import each.
Future<void> importProfileFile(BuildContext context) => runGuarded(context, () async {
      final files = await DV.Platform.fileStorage.pick(multiple: true);
      for (final file in files) {
        final bytes = await file.readBytes();
        if (bytes.length > 1024 * 1024) throw FormatException('${file.name}: file too large');
        final name = file.name.contains('.') ? file.name.substring(0, file.name.lastIndexOf('.')) : file.name;
        await ProfileStore.importText(utf8.decode(bytes, allowMalformed: true), name: name);
      }
    }, title: tr(Strings.globalActionsImport));

// ---------------------------------------------------------------------------
// Installed profile header

/// `InstalledProfileView`: the active profile pinned on top, with its status and switch.
class const InstalledProfileHeader({final bool grid = false}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tunnel = context.global<TunnelState>();
    final profiles = context.global<ProfilesState>();
    final active = tunnel.activeProfileId == null ? null : profiles.byId(tunnel.activeProfileId!);
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: .w600);
    return Card(
      elevation: 0,
      margin: const .fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: .circular(10)),
      child: Padding(
        padding: const .fromLTRB(16, 16, 12, 16),
        child: Row(children: <Widget>[
          Expanded(
            child: Column(crossAxisAlignment: .start, children: <Widget>[
              if (active == null)
                Text(tr(Strings.viewsAppInstalledProfileNoneName), style: nameStyle)
              else
                ProfileMenuButton(
                  profile: active,
                  installed: true,
                  child: Row(mainAxisSize: .min, children: <Widget>[
                    Flexible(child: Text(active.name, style: nameStyle)),
                    const Icon(Icons.expand_more, size: 20),
                  ]),
                ),
              const SizedBox(height: 12),
              if (active == null)
                Text(tr(Strings.viewsAppInstalledProfileNoneStatus),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
              else
                ConnectionStatusText(profileId: active.id),
            ]),
          ),
          if (active != null) TunnelToggle(profileId: active.id),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List and grid

class const _ProfileList({final Widget? header, required final List<TunnelProfile> profiles}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSForm(children: <Widget>[
        ?header,
        PSSection(
          header: tr(Strings.viewsAppFoldersDefault),
          children: <Widget>[
            for (final profile in profiles)
              Dismissible(
                key: ValueKey<String>(profile.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: PSColors.error,
                  alignment: Alignment.centerRight,
                  padding: const .only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => confirmDeleteProfile(context, profile),
                child: ProfileRow(profile: profile),
              ),
          ],
        ),
      ]);
}

class const _ProfileGrid({final Widget? header, required final List<TunnelProfile> profiles}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        padding: const .all(8),
        children: <Widget>[
          ?header,
          Padding(
            padding: const .fromLTRB(16, 8, 16, 0),
            child: GridView.extent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 2.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[for (final profile in profiles) _ProfileGridCell(profile: profile)],
            ),
          ),
        ],
      );
}

class const _ProfileGridCell({required final TunnelProfile profile}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = context.global<TunnelState>().isActive(profile.id);
    return ProfileMenuButton(
      profile: profile,
      asContextMenu: true,
      child: Material(
        color: active ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
        borderRadius: .circular(10),
        child: InkWell(
          borderRadius: .circular(10),
          onTap: () => TunnelStore.toggle(profile).catchError((Object error) {
            if (context.mounted) showErrorAlert(context, title: profile.name, message: '$error');
          }),
          child: Padding(
            padding: const .all(14),
            child: Row(children: <Widget>[
              Expanded(child: _ProfileCard(profile: profile)),
              IconButton(
                tooltip: tr(Strings.globalActionsEdit),
                icon: const Icon(Icons.info_outline),
                onPressed: () => editProfile(profile),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// `ProfileRowView`: card (tap to edit), then the connect switch.
class const ProfileRow({super.key, required final TunnelProfile profile}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ProfileMenuButton(
        profile: profile,
        asContextMenu: true,
        child: InkWell(
          onTap: () => editProfile(profile),
          child: Padding(
            padding: const .fromLTRB(16, 10, 12, 10),
            child: Row(children: <Widget>[
              Expanded(child: _ProfileCard(profile: profile)),
              TunnelToggle(profileId: profile.id),
            ]),
          ),
        ),
      );
}

/// `ProfileCardView`: name (headline) over its status (subheadline).
class const _ProfileCard({required final TunnelProfile profile}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: .start, mainAxisSize: .min, children: <Widget>[
      Text(profile.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: .w600)),
      const SizedBox(height: 2),
      ConnectionStatusText(profileId: profile.id, style: theme.textTheme.bodyMedium),
    ]);
  }
}

void editProfile(TunnelProfile profile) {
  DraftStore.open(profile.id);
  DV.Navigation.push(DVRoutes.profiles(id: profile.id));
}

Future<bool> confirmDeleteProfile(BuildContext context, TunnelProfile profile) async {
  final confirmed = await confirmDestructive(
    context,
    title: tr(Strings.globalActionsRemove),
    message: profile.name,
    action: tr(Strings.globalActionsRemove),
  );
  if (confirmed) await ProfileStore.remove(profile.id);
  return confirmed;
}

/// `ProfileContextMenu`: Reconnect | Edit, then Hide (installed) or Duplicate, Delete.
/// As a context menu it opens on right-click and long-press; otherwise on tap.
class const ProfileMenuButton({
  super.key,
  required final TunnelProfile profile,
  required final Widget child,
  final bool installed = false,
  final bool asContextMenu = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = MenuController();
    final items = <Widget>[
      MenuItemButton(
        leadingIcon: const Icon(Icons.refresh),
        onPressed: () => runGuarded(context, () => TunnelStore.reconnect(profile)),
        child: Text(tr(Strings.globalActionsReconnect)),
      ),
      const Divider(height: 1),
      MenuItemButton(
        leadingIcon: const Icon(Icons.edit_outlined),
        onPressed: () => editProfile(profile),
        child: Text(tr(Strings.globalActionsEdit)),
      ),
      if (installed)
        MenuItemButton(
          leadingIcon: const Icon(Icons.visibility_off_outlined),
          onPressed: () => PreferencesStore.update((p) => p.copyWith(pinsActiveProfile: false)),
          child: Text(tr(Strings.globalActionsHide)),
        ),
      if (!installed) ...<Widget>[
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_outlined),
          onPressed: () => runGuarded(context, () => ProfileStore.duplicate(profile.id)),
          child: Text(tr(Strings.globalActionsDuplicate)),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline, color: PSColors.error),
          onPressed: () => confirmDeleteProfile(context, profile),
          child: Text(tr(Strings.globalActionsRemove), style: const TextStyle(color: PSColors.error)),
        ),
      ],
    ];
    return MenuAnchor(
      controller: controller,
      menuChildren: items,
      child: asContextMenu
          ? GestureDetector(
              onSecondaryTapDown: (details) => controller.open(position: details.localPosition),
              onLongPressStart: (details) => controller.open(position: details.localPosition),
              child: child,
            )
          : InkWell(
              borderRadius: .circular(6),
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              child: child,
            ),
    );
  }
}
