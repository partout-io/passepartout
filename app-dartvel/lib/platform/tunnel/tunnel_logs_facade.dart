// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Tunnel logs on every target: the dart:io files where there are files, and
// no logs on the web (a browser runs no tunnel).
export 'tunnel_logs_stub.dart' if (dart.library.io) 'tunnel_logs_io.dart';
