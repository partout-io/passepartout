// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import '../../kit.dart';

/// Full-screen viewer for long cryptographic or configuration content
/// (CA certificate, client certificate, client key, TLS wrap key, data ciphers, XOR):
/// the kit's read-only [PSLongContentPage]. The module view opens it by URL,
/// `/profiles/<id>/modules/<moduleId>/<section>` (see `openVPNSubpage`).
class const OpenVPNContentScreen({super.key, required final String title, required final String content}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => PSLongContentPage(title: title, text: content);
}
