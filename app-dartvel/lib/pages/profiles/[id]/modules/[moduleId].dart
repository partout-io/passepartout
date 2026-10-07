// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:flutter/material.dart';
import '../../../../dartvel_client/dartvel_client.dart';
import '../../../../ui/modules/module_screen.dart';
@DVPage(title: 'Module', showAppBar: false)
Widget _modulePage(BuildContext context) => ModuleScreen(profileId: context.dvParams['id']!, moduleId: context.dvParams['moduleId']!);
