// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../dartvel_client/dartvel_client.dart';

@DVPage(
  title: 'Dartvel',
  showAppBar: true,
  centerTitle: true,
)
@pragma('vm:entry-point')
Widget _indexPage(BuildContext context) => buildIndexPage(context);

Widget buildIndexPage(BuildContext context) {
  final loadedAt = DateTime.now().toIso8601String();

  return DVBox.list([
      const DVText('Welcome to Dartvel'),
      const DVText('DARTVEL').modifier(
        DVModifier().fontSize(28).fontWeight(.w800),
      ),
      const DVText('Your Dartvel app is ready!').modifier(
        DVModifier().color(Color(0xFF111827)).padding(8),
      ),
      DVText('Loaded at: $loadedAt'),
      DVBox.wrapLine([
        const DVText('Docs').modifier(DVModifier().padding(12).rounded(8)),
        const DVText('GitHub').modifier(DVModifier().padding(12).rounded(8)),
      ], spacing: 12),
    ]).modifier(
      const DVModifier().padding(24).align(.center),
    );
}
