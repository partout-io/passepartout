// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../../kit.dart';

/// Full-screen viewer for long cryptographic or configuration content
/// (CA certificate, client certificate, client key, TLS wrap key, data ciphers, XOR).
/// Pushed with `Navigator.push` of a `PSScaffold`.
class OpenVPNContentScreen extends StatelessWidget {
  const OpenVPNContentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PSScaffold(
      title: title,
      actions: <Widget>[
        IconButton(
          tooltip: 'Copy',
          icon: const Icon(Icons.copy),
          onPressed: () => copyToClipboard(context, content),
        ),
      ],
      body: PSForm(
        children: <Widget>[
          PSSection(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
