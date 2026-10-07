// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:flutter/material.dart';
import '../../../dartvel_client/dartvel_client.dart';
import '../../../ui/screens/profile_editor_screen.dart';
@DVPage(title: 'Profile', showAppBar: false)
Widget _profilePage(BuildContext context) => ProfileEditorScreen(profileId: context.dvParams['id']!);
