// SPDX-License-Identifier: GPL-3.0
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef EventNative = Void Function(Int, Pointer<Char>, Uint64, Uint64);
typedef StartNative = Int Function(
  Pointer<Utf8>,
  Pointer<Utf8>,
  Pointer<NativeFunction<EventNative>>,
);

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: partout-tunnel PROFILE.json');
    exitCode = 64;
    return;
  }
  void emit(Map<String, Object?> event) => stdout.writeln(jsonEncode(event));
  // Read before creating listeners so a missing profile cannot keep the
  // isolate alive after startup failure.
  try {
    final profileText = await File(args.single).readAsString();
    final base = File(Platform.resolvedExecutable).parent.path;
    final bridge = DynamicLibrary.open('$base/libtunnel_bridge.so');
    final free = bridge
        .lookupFunction<
          Void Function(Pointer<Void>),
          void Function(Pointer<Void>)
        >('tunnel_free');
    final stop = bridge.lookupFunction<Void Function(), void Function()>(
      'tunnel_stop',
    );
    final done = Completer<void>();
    final listener = NativeCallable<EventNative>.listener((
      int kind,
      Pointer<Char> text,
      int a,
      int b,
    ) {
      String? value;
      try {
        value = text == nullptr ? null : text.cast<Utf8>().toDartString();
      } finally {
        if (text != nullptr) free(text.cast());
      }
      switch (kind) {
        case 0:
          emit({'type': 'status', 'status': value});
        case 1:
          emit({'type': 'data', 'received': a, 'sent': b});
        case 2:
          emit({'type': 'error', 'code': value});
        case 3:
          emit({'type': 'log', 'level': a, 'message': value});
        case 4:
          emit({'type': 'exit', 'code': a});
          exitCode = a == 0 ? 0 : 1;
          if (!done.isCompleted) done.complete();
      }
    });
    listener.keepIsolateAlive = false;
    final json = profileText.toNativeUtf8();
    // Always use the installed library beside the executable: no elevated
    // environment-controlled library loading or command-line library override.
    final library = '$base/libpartout.so'.toNativeUtf8();
    final start = bridge
        .lookupFunction<
          StartNative,
          int Function(
            Pointer<Utf8>,
            Pointer<Utf8>,
            Pointer<NativeFunction<EventNative>>,
          )
        >('tunnel_start');
    // A stop request can arrive while Partout is still initializing on its
    // thread. Retry until completion so the request cannot be lost.
    bool stopping = false;
    void requestStop() {
      stopping = true;
      stop();
    }

    final stopTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (stopping && !done.isCompleted) stop();
    });
    final signals = <StreamSubscription<ProcessSignal>>[];
    signals.add(ProcessSignal.sigterm.watch().listen((_) => requestStop()));
    signals.add(ProcessSignal.sigint.watch().listen((_) => requestStop()));
    final input = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim() == 'stop') requestStop();
        }, onDone: requestStop);
    final result = start(library, json, listener.nativeFunction);
    malloc.free(json);
    malloc.free(library);
    if (result != 0) {
      emit({'type': 'error', 'code': 'helper_start_$result'});
      exitCode = 1;
    } else {
      emit({'type': 'ready', 'pid': pid});
      await done.future;
    }
    stopTimer.cancel();
    await input.cancel();
    for (final signal in signals) {
      await signal.cancel();
    }
    // Completion is posted after all native work ends; drain queued listeners.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    listener.close();
  } catch (error) {
    emit({
      'type': 'error',
      'code': 'helper_failure',
      'message': error.toString(),
    });
    exitCode = 1;
  }
}
