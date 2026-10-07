// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev
import 'package:dartvel_core/dartvel.dart';

@DVModel(generatePublicPages: false, subject: DVSubject.self, retain: DVRetention.indefinite)
class const _VpnProfile({required final String id, required final String name,
  @DVModel.sensitiveField() required final String configuration});
