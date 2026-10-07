// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream builds every module on "Save" and shows the first
// `PartoutError.invalidField` it throws. Edits here write JSON at once, so the
// raw text that would fail lives in the editors' builders; this asks them.

import '../../../domain/profile.dart';
import '../dns_view.dart';
import '../http_proxy_view.dart';

/// The localised save-time error of [module], or null when it would build.
/// IP and on-demand modules never fail to build upstream.
String? moduleValidationError(TaggedModule module) => switch (module.type) {
      ModuleType.dns => dnsValidationError(module),
      ModuleType.httpProxy => httpProxyValidationError(module),
      _ => null,
    };
