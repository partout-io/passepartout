// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:flutter/material.dart';
import '../../../dartvel_client/dartvel_client.dart';
import '../../../ui/profile_screens.dart';
@DVPage(title: 'Profile', showAppBar: true)
Widget _profilePage(BuildContext context) => ProfileScreen(id: context.dvParams['id']!);
