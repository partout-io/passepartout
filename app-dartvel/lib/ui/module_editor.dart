// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../dartvel_client/dartvel_client.dart';
import '../domain/profile.dart';
import 'profile_screens.dart';

class const ModuleEditor({super.key, required final String id, required final bool dns}) extends StatefulWidget {
  @override State<ModuleEditor> createState() => _ModuleEditorState();
}
class _ModuleEditorState extends State<ModuleEditor> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  late final Future<void> _loaded = _load();
  VpnProfile? _stored; TunnelProfile? _profile; TaggedModule? _module;
  String _protocol = 'cleartext'; String _route = 'default';
  bool _inherits = false; bool _only = false; bool _primary = false;
  bool _busy = false; String? _error;
  TextEditingController field(String name) => _fields.putIfAbsent(name, () => TextEditingController());
  List<String> entries(String name) => field(name).text.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  String? optional(String name) => field(name).text.trim().isEmpty ? null : field(name).text.trim();
  Future<void> _load() async {
    _stored = await VpnProfile.find(widget.id);
    if (_stored == null) throw const FormatException('Profile not found');
    _profile = TunnelProfile.decode(_stored!.configuration);
    final matches = _profile!.modules.where((m) => m.type == (widget.dns ? 'DNS' : 'HTTPProxy'));
    _module = matches.isEmpty ? null : matches.first;
    final value = _module?.value ?? <String, dynamic>{};
    if (widget.dns) {
      final protocol = value['protocolType'] as Map? ?? {'type': 'cleartext'};
      _protocol = protocol['type'] as String;
      _inherits = value['inheritsVPN'] == true; _only = value['domainPolicy'] == 'matchAndSearch';
      _route = value['routesThroughVPN'] == null ? 'default' : value['routesThroughVPN'] == true ? 'yes' : 'no';
      field('url').text = protocol['url'] as String? ?? '';
      field('hostname').text = protocol['hostname'] as String? ?? '';
      field('servers').text = (value['servers'] as List? ?? []).join('\n');
      final domains = [if (value['domainName'] != null) value['domainName'], ...value['searchDomains'] as List? ?? []];
      field('domains').text = domains.join('\n'); _primary = value['domainName'] != null;
    } else {
      field('proxy').text = value['proxy'] as String? ?? '';
      field('secureProxy').text = value['secureProxy'] as String? ?? '';
      field('pacURL').text = value['pacURL'] as String? ?? '';
      field('bypassDomains').text = (value['bypassDomains'] as List? ?? []).join('\n');
    }
  }
  @override void dispose() { for (final controller in _fields.values) { controller.dispose(); } super.dispose(); }
  Widget input(String name, String label, {bool multiline = false, String? Function(String?)? validator}) =>
    Padding(padding: const .only(bottom: 16), child: TextFormField(controller: field(name),
      minLines: multiline ? 3 : 1, maxLines: multiline ? 6 : 1,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: multiline),
      validator: validator, onFieldSubmitted: multiline ? null : (_) => _save()));
  String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = Uri.tryParse(value.trim());
    return parsed != null && ['http', 'https'].contains(parsed.scheme) && parsed.host.isNotEmpty ? null : 'Enter an HTTP or HTTPS URL';
  }
  String? endpoint(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = Uri.tryParse('http://${value.trim()}');
    try { return parsed != null && parsed.host.isNotEmpty && parsed.hasPort && parsed.port > 0 && parsed.port <= 65535 && parsed.path.isEmpty ? null : 'Enter address:port (IPv6 in brackets)'; }
    catch (_) { return 'Enter address:port'; }
  }
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final id = _module?.id ?? const Uuid().v4();
      final TaggedModule edited;
      if (widget.dns) {
        final domains = entries('domains');
        if (_protocol == 'https' && optional('url') == null && !_inherits) throw const FormatException('DNS over HTTPS URL is required');
        if (_protocol == 'tls' && optional('hostname') == null && !_inherits) throw const FormatException('DNS over TLS hostname is required');
        edited = DnsSettings(id: id, protocolType: {'type': _protocol,
          if (_protocol == 'https') 'url': field('url').text.trim(),
          if (_protocol == 'tls') 'hostname': field('hostname').text.trim()},
          servers: entries('servers'), inheritsVPN: _inherits,
          domainName: _primary && domains.isNotEmpty ? domains.first : null,
          searchDomains: _primary && domains.isNotEmpty ? domains.skip(1).toList() : domains,
          domainPolicy: _only ? 'matchAndSearch' : null,
          routesThroughVPN: _route == 'default' ? null : _route == 'yes').toModule();
      } else {
        edited = HttpProxySettings(id: id, proxy: optional('proxy'), secureProxy: optional('secureProxy'),
          pacURL: optional('pacURL'), bypassDomains: entries('bypassDomains')).toModule();
      }
      final next = _profile!.replaceModule(edited);
      await _stored!.copyWith(configuration: next.encode()).save();
      if (mounted) context.go(DVRoutes.profilesId.withId(widget.id));
    } on FormatException catch (error) { if (mounted) setState(() => _error = error.message); }
    catch (_) { if (mounted) setState(() => _error = 'Unable to save. Please try again.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => FutureBuilder<void>(future: _loaded, builder: (context, snapshot) {
    if (snapshot.hasError) return frame(context, widget.dns ? 'DNS' : 'HTTP proxy', [const Text('Unable to load profile.')]);
    if (snapshot.connectionState != .done) return const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading module'));
    return frame(context, widget.dns ? 'DNS' : 'HTTP proxy', [Form(key: _form,
      child: Column(crossAxisAlignment: .stretch, children: [
        if (widget.dns) ...[
          SwitchListTile(title: const Text('Inherit DNS settings from VPN'), value: _inherits, onChanged: (v) => setState(() => _inherits = v)),
          DropdownButtonFormField<String>(initialValue: _route, decoration: const InputDecoration(labelText: 'Route DNS through VPN'),
            items: const [DropdownMenuItem(value: 'default', child: Text('Default')), DropdownMenuItem(value: 'yes', child: Text('Yes')), DropdownMenuItem(value: 'no', child: Text('No'))], onChanged: (v) => setState(() => _route = v!)),
          SwitchListTile(title: const Text('Use only in specified domains'), value: _only, onChanged: _inherits || _protocol == 'cleartext' ? (v) => setState(() => _only = v) : null),
          if (!_inherits) ...[
            const SizedBox(height: 16), Text('Custom settings', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(initialValue: _protocol, decoration: const InputDecoration(labelText: 'Protocol'),
              items: const [DropdownMenuItem(value: 'cleartext', child: Text('Cleartext')), DropdownMenuItem(value: 'https', child: Text('HTTPS')), DropdownMenuItem(value: 'tls', child: Text('TLS'))], onChanged: (v) => setState(() => _protocol = v!)),
            const SizedBox(height: 16),
            if (_protocol == 'https') input('url', 'URL', validator: url),
            if (_protocol == 'tls') input('hostname', 'Hostname'),
            input('servers', 'DNS servers (one per line)', multiline: true),
            if (_protocol == 'cleartext') ...[
              input('domains', 'Domains (one per line)', multiline: true),
              SwitchListTile(title: const Text('First domain is primary'), value: _primary, onChanged: (v) => setState(() => _primary = v)),
            ],
          ],
        ] else ...[
          Text('HTTP', style: Theme.of(context).textTheme.titleMedium), input('proxy', 'Address:port', validator: endpoint),
          Text('HTTPS', style: Theme.of(context).textTheme.titleMedium), input('secureProxy', 'Secure address:port', validator: endpoint),
          Text('PAC', style: Theme.of(context).textTheme.titleMedium), input('pacURL', 'URL', validator: url),
          input('bypassDomains', 'Bypass domains (one per line)', multiline: true),
        ],
        if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        const SizedBox(height: 16), FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving…' : 'Save')),
        TextButton(onPressed: () => context.go(DVRoutes.profilesId.withId(widget.id)), child: const Text('Cancel')),
      ]))]);
  });
}
