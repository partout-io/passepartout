// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../dartvel_client/dartvel_client.dart';
import '../domain/profile.dart';
import '../platform/vpn_service.dart';

Widget frame(BuildContext context, String title, List<Widget> children) =>
  SingleChildScrollView(child: Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 840),
    child: Padding(padding: const .all(24), child: Column(
      crossAxisAlignment: .stretch, children: [
        Row(children: [Image.asset('assets/icon.png', width: 40, height: 40), const SizedBox(width: 12),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium))]),
        const SizedBox(height: 24), ...children,
      ])))));

class const ProfilesScreen({super.key}) extends StatefulWidget {
  @override State<ProfilesScreen> createState() => _ProfilesState();
}
class _ProfilesState extends State<ProfilesScreen> {
  late Future<List<VpnProfile>> _profiles = VpnProfile.all();
  @override Widget build(BuildContext context) => frame(context, 'Profiles', [
    Text('Your VPN profiles', style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 16),
    Align(alignment: .centerLeft, child: FilledButton.icon(
      icon: const Icon(Icons.add), label: const Text('Import profile'),
      onPressed: () => context.go(DVRoutes.profilesImport.path))),
    const SizedBox(height: 24),
    FutureBuilder<List<VpnProfile>>(future: _profiles, builder: (context, snapshot) {
      if (snapshot.hasError) return Column(children: [
        const Text('Unable to load profiles.', semanticsLabel: 'Error: unable to load profiles'),
        TextButton(onPressed: () => setState(() => _profiles = VpnProfile.all()), child: const Text('Retry'))]);
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading profiles'));
      if (snapshot.data!.isEmpty) return const Padding(padding: .symmetric(vertical: 48),
        child: Text('No profiles. Import an OpenVPN or WireGuard configuration to get started.', textAlign: .center));
      return Column(children: snapshot.data!.map((profile) => Card(child: ListTile(
        leading: const Icon(Icons.vpn_key_outlined), title: Text(profile.name), subtitle: const Text('Disconnected'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(DVRoutes.profilesId.withId(profile.id)),
      ))).toList());
    }),
  ]);
}

class const ImportScreen({super.key}) extends StatefulWidget {
  @override State<ImportScreen> createState() => _ImportState();
}
class _ImportState extends State<ImportScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(); final _text = TextEditingController();
  bool _busy = false; String? _error;
  @override void dispose() { _name.dispose(); _text.dispose(); super.dispose(); }
  Future<void> _import() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final json = kIsWeb ? await importProfile(text: _text.text, name: _name.text) :
        VpnService.instance.importProfile(_text.text, _name.text).encode();
      final profile = TunnelProfile.decode(json);
      await VpnProfile(id: profile.id, name: profile.name, configuration: profile.encode()).save();
      if (mounted) context.go(DVRoutes.profilesId.withId(profile.id));
    } catch (_) { if (mounted) setState(() => _error = 'Unable to import. Check the configuration and engine availability.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _pick() async {
    try {
      final files = await DV.Platform.fileStorage.pick();
      if (files.isEmpty) return;
      final bytes = await files.first.readBytes();
      if (bytes.length > 1024 * 1024) throw const FormatException('Too large');
      _text.text = utf8.decode(bytes);
      if (_name.text.isEmpty) _name.text = files.first.name;
    } catch (_) { if (mounted) setState(() => _error = 'Unable to read file. Paste the configuration below.'); }
  }
  @override Widget build(BuildContext context) => frame(context, 'Import profile', [
    const Text('OpenVPN (.ovpn) or WireGuard (.conf)'), const SizedBox(height: 16),
    Form(key: _form, child: Column(crossAxisAlignment: .stretch, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'),
        textInputAction: .next, validator: (value) => value!.trim().isEmpty ? 'Name is required' : null,
        onFieldSubmitted: (_) => _import()),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: _busy ? null : _pick, icon: const Icon(Icons.upload_file), label: const Text('Import from file')),
      const SizedBox(height: 16),
      TextFormField(controller: _text, minLines: 8, maxLines: 16,
        decoration: const InputDecoration(labelText: 'Configuration', alignLabelWithHint: true),
        validator: (value) => value!.trim().isEmpty ? 'Configuration is required' : null),
      const SizedBox(height: 16),
      if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
      FilledButton(onPressed: _busy ? null : _import, child: Text(_busy ? 'Importing…' : 'Import')),
      TextButton(onPressed: () => context.go(DVRoutes.index.path), child: const Text('Cancel')),
    ])),
  ]);
}

class const ProfileScreen({super.key, required final String id}) extends StatefulWidget {
  @override State<ProfileScreen> createState() => _ProfileState();
}
class _ProfileState extends State<ProfileScreen> {
  @override Widget build(BuildContext context) => FutureBuilder<VpnProfile?>(
    future: VpnProfile.find(widget.id), builder: (context, snapshot) {
      if (snapshot.hasError) return frame(context, 'Profile', [const Text('Unable to load profile.')]);
      if (snapshot.connectionState != .done) return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading profile'));
      if (snapshot.data == null) return frame(context, 'Profile', [const Text('Profile not found.')]);
      final profile = TunnelProfile.decode(snapshot.data!.configuration);
      return frame(context, profile.name, [
        const Text('Disconnected'), const SizedBox(height: 12),
        const Text('Connection needs the platform VPN helper. Profile management is available.'),
        const SizedBox(height: 24), Text('Modules', style: Theme.of(context).textTheme.titleLarge),
        ...profile.modules.map((module) => Card(child: ListTile(
          title: Text(module.type), subtitle: Text((profile.json['activeModulesIds'] as List).contains(module.id) ? 'Enabled' : 'Disabled'),
          trailing: module.type == 'DNS' || module.type == 'HTTPProxy' ? const Icon(Icons.edit_outlined) : null,
          onTap: module.type == 'DNS' ? () => context.go(DVRoutes.profilesIdDns.withId(widget.id)) :
            module.type == 'HTTPProxy' ? () => context.go(DVRoutes.profilesIdHttpProxy.withId(widget.id)) : null,
        ))),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: () => context.go(DVRoutes.profilesIdDns.withId(widget.id)), child: const Text('DNS')),
        OutlinedButton(onPressed: () => context.go(DVRoutes.profilesIdHttpProxy.withId(widget.id)), child: const Text('HTTP proxy')),
        TextButton(onPressed: () => context.go(DVRoutes.index.path), child: const Text('Profiles')),
      ]);
    });
}
