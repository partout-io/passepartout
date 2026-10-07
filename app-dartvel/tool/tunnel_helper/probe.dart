// SPDX-License-Identifier: GPL-3.0
// Unprivileged smoke attempt; never changes system privilege configuration.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'package:passepartout/platform/generated/partout_bindings.dart';

Future<void> main(List<String> args) async {
  final dir = args.isEmpty ? '/tmp/pp-tunnel-build' : args.first;
  final abi = PartoutBindings(DynamicLibrary.open('$dir/libpartout.so'));
  abi.partout_init(nullptr);
  final input = (await File('test/fixtures/sample.conf').readAsString())
      .replaceAll('wg.example.com:51820', '127.0.0.1:51820')
      .toNativeUtf8();
  final name = 'Unprivileged dummy probe'.toNativeUtf8();
  final result = abi.partout_import_profile(input.cast(), name.cast());
  malloc.free(input);
  malloc.free(name);
  if (result == nullptr) throw StateError('Import failed');
  final envelope = jsonDecode(result.cast<Utf8>().toDartString()) as Map;
  malloc.free(result);
  final temp = await Directory.systemTemp.createTemp('partout-probe-');
  try {
    final profile = File('${temp.path}/profile.json');
    await profile.writeAsString(jsonEncode(envelope['payload']));
    await Process.run('/bin/chmod', ['600', profile.path]);
    final process = await Process.start('$dir/partout-tunnel', [profile.path]);
    final output = process.stdout.transform(utf8.decoder).listen(stdout.write);
    final error = process.stderr.transform(utf8.decoder).listen(stderr.write);
    final timer = Timer(const Duration(seconds: 3), () {
      if (args.contains('--sigterm')) {
        Process.killPid(process.pid, ProcessSignal.sigterm);
      } else {
        process.stdin.writeln('stop');
      }
    });
    await process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        Process.killPid(process.pid, ProcessSignal.sigterm);
        return 124;
      },
    );
    timer.cancel();
    await output.cancel();
    await error.cancel();
  } finally {
    await temp.delete(recursive: true);
  }
}
