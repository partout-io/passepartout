// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// GET /api/health
import 'package:dartvel_core/dartvel.dart';

@DVBackendFunction()
Map<String, Object?> _health() => <String, Object?>{
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
    };
