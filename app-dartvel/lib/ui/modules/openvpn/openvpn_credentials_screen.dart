// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../../../domain/profile.dart';
import '../../../l10n/strings.g.dart';
import '../../kit.dart';
import 'openvpn_formatters.dart';

/// Screen for editing OpenVPN credentials and interactive OTP settings.
/// Matches upstream `OpenVPNCredentialsGroup`.
class OpenVPNCredentialsScreen extends StatefulWidget {
  const OpenVPNCredentialsScreen({
    super.key,
    required this.module,
    required this.onChanged,
  });

  final TaggedModule module;
  final ValueChanged<TaggedModule> onChanged;

  @override
  State<OpenVPNCredentialsScreen> createState() => _OpenVPNCredentialsScreenState();
}

class _OpenVPNCredentialsScreenState extends State<OpenVPNCredentialsScreen> {
  late TaggedModule _module;

  @override
  void initState() {
    super.initState();
    _module = widget.module;
  }

  Map<String, dynamic> get _credentials {
    final raw = _module.value['credentials'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  bool get _isInteractive => _module.value['requiresInteractiveCredentials'] == true;

  String get _otpMethod => (_credentials['otpMethod'] as String?)?.toLowerCase() ?? 'none';

  void _updateCredentials({
    String? username,
    String? password,
    String? otpMethod,
    bool? isInteractive,
  }) {
    final creds = _credentials;
    if (username != null) creds['username'] = username;
    if (password != null) creds['password'] = password;
    if (otpMethod != null) creds['otpMethod'] = otpMethod;

    final nextValue = Map<String, dynamic>.from(_module.value);
    nextValue['credentials'] = creds;
    if (isInteractive != null) {
      nextValue['requiresInteractiveCredentials'] = isInteractive;
    }

    final updated = _module.withValue(nextValue);
    setState(() {
      _module = updated;
    });
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final creds = _credentials;
    final isInteractive = _isInteractive;
    final otpMethod = _otpMethod;
    final approachDescription = formatOtpApproach(otpMethod);

    return PSScaffold(
      title: tr(Strings.modulesOpenvpnCredentials),
      body: PSForm(
        children: <Widget>[
          PSSection(
            footer: tr(Strings.modulesOpenvpnCredentialsInteractiveFooter),
            children: <Widget>[
              PSToggleRow(
                title: tr(Strings.modulesOpenvpnCredentialsInteractive),
                value: isInteractive,
                onChanged: (val) => _updateCredentials(isInteractive: val),
              ),
              if (isInteractive)
                PSPickerRow<String>(
                  title: 'OTP',
                  value: otpMethod,
                  options: const <String>['none', 'append', 'encode'],
                  label: formatOtpMethod,
                  onChanged: (method) => _updateCredentials(otpMethod: method),
                ),
            ],
          ),
          if (isInteractive && approachDescription.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: Text(
                approachDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          PSSection(
            children: <Widget>[
              PSTextRow(
                label: tr(Strings.globalNounsUsername),
                value: (creds['username'] as String?) ?? '',
                placeholder: tr(Strings.placeholdersUsername),
                onChanged: (val) => _updateCredentials(username: val),
              ),
              PSTextRow(
                label: tr(Strings.globalNounsPassword),
                value: (creds['password'] as String?) ?? '',
                placeholder: tr(Strings.placeholdersSecret),
                obscure: true,
                onChanged: (val) => _updateCredentials(password: val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
