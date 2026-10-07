// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:dartvel_core/dartvel.dart';
import '../../platform/vpn_service.dart';
@DVBackendFunction()
Future<String> _importProfileText({required String text, required String name}) async {
  if (text.length > 1024 * 1024) throw const FormatException('Configuration exceeds 1 MB');
  if (name.trim().isEmpty) throw const FormatException('Name is required');
  return (await VpnService.instance.importProfile(text, name.trim())).encode();
}
