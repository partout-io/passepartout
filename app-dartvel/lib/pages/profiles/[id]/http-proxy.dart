// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:flutter/material.dart';
import '../../../dartvel_client/dartvel_client.dart';
import '../../../ui/module_editor.dart';
@DVPage(title: 'HTTP proxy', showAppBar: true)
Widget _modulePage(BuildContext context) => ModuleEditor(id: context.dvParams['id']!, dns: false);
