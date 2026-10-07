// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter/material.dart';
import 'dartvel_client/dartvel_client.dart';

void main(List<String> arguments) async {
  // Where this launch renders: nothing to decide unless the build opted into
  // the terminal, in which case a launch with no display may leave for it.
  await negotiateDartvelLaunch(arguments);
  runApp(createDartvelApp(arguments: arguments));
}

// The arguments are what a file association, an app link or a second
// launch hands a desktop application; the router opens them.
Widget createDartvelApp({List<String> arguments = const <String>[]}) {
  return MaterialApp.router(
    title: 'Dartvel App',
    theme: dartvelDefaultTheme(.light),
    darkTheme: dartvelDefaultTheme(.dark),
    themeMode: .system,
    routerConfig: createDartvelRouter(arguments: arguments),
  );
}
