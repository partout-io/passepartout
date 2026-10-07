// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../../../domain/profile.dart';
import '../../../l10n/strings.g.dart';
import '../../kit.dart';
import 'openvpn_formatters.dart';

/// Screen for managing remote endpoints of an OpenVPN module.
/// Matches upstream `OpenVPNView+Remotes.swift`.
class OpenVPNRemotesScreen extends StatefulWidget {
  const OpenVPNRemotesScreen({
    super.key,
    required this.module,
    required this.onChanged,
  });

  final TaggedModule module;
  final ValueChanged<TaggedModule> onChanged;

  @override
  State<OpenVPNRemotesScreen> createState() => _OpenVPNRemotesScreenState();
}

class _OpenVPNRemotesScreenState extends State<OpenVPNRemotesScreen> {
  late TaggedModule _module;

  @override
  void initState() {
    super.initState();
    _module = widget.module;
  }

  Map<String, dynamic> get _configuration {
    final raw = _module.value['configuration'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  List<String> get _rawRemotes {
    final remotes = _configuration['remotes'];
    if (remotes is List) {
      return remotes.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  void _saveRemotes(List<String> newRemotes) {
    final config = _configuration;
    config['remotes'] = newRemotes;

    final nextValue = Map<String, dynamic>.from(_module.value);
    nextValue['configuration'] = config;

    final updated = _module.withValue(nextValue);
    setState(() {
      _module = updated;
    });
    widget.onChanged(updated);
  }

  void _addRemote() {
    final remotes = _rawRemotes;
    remotes.add('vpn.example.com:UDP:1194');
    _saveRemotes(remotes);
  }

  void _removeRemote(int index) {
    final remotes = _rawRemotes;
    if (index >= 0 && index < remotes.length) {
      remotes.removeAt(index);
      _saveRemotes(remotes);
    }
  }

  void _updateRemote(int index, ParsedRemote parsed) {
    final remotes = _rawRemotes;
    if (index >= 0 && index < remotes.length) {
      remotes[index] = parsed.toRaw();
      _saveRemotes(remotes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remotes = _rawRemotes;

    return PSScaffold(
      title: tr(Strings.modulesOpenvpnRemotes),
      body: PSForm(
        children: <Widget>[
          PSSection(
            children: <Widget>[
              for (var i = 0; i < remotes.length; i++)
                _RemoteItemRow(
                  key: ValueKey<int>(i),
                  parsed: ParsedRemote.parse(remotes[i]),
                  onChanged: (updated) => _updateRemote(i, updated),
                  onDelete: () => _removeRemote(i),
                ),
              PSRow(
                title: tr(Strings.globalActionsAdd),
                leading: const Icon(Icons.add_circle, color: PSColors.active),
                onTap: _addRemote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoteItemRow extends StatefulWidget {
  const _RemoteItemRow({
    super.key,
    required this.parsed,
    required this.onChanged,
    required this.onDelete,
  });

  final ParsedRemote parsed;
  final ValueChanged<ParsedRemote> onChanged;
  final VoidCallback onDelete;

  @override
  State<_RemoteItemRow> createState() => _RemoteItemRowState();
}

class _RemoteItemRowState extends State<_RemoteItemRow> {
  late final TextEditingController _addressController =
      TextEditingController(text: '${widget.parsed.address}:${widget.parsed.port}');

  @override
  void didUpdateWidget(_RemoteItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expected = '${widget.parsed.address}:${widget.parsed.port}';
    if (_addressController.text != expected) {
      _addressController.text = expected;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    final parts = value.split(':');
    final String address;
    final int port;
    if (parts.length >= 2) {
      address = parts.sublist(0, parts.length - 1).join(':');
      port = int.tryParse(parts.last) ?? widget.parsed.port;
    } else {
      address = value;
      port = widget.parsed.port;
    }
    widget.onChanged(widget.parsed.copyWith(address: address, port: port));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: tr(Strings.globalActionsDelete),
            icon: const Icon(Icons.remove_circle, color: PSColors.error),
            onPressed: widget.onDelete,
          ),
          Expanded(
            child: TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'host:port',
              ),
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: _onAddressChanged,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.parsed.socketType,
              items: ParsedRemote.socketTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  widget.onChanged(widget.parsed.copyWith(socketType: val));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
