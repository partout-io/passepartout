// SPDX-License-Identifier: GPL-3.0
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:passepartout/platform/tunnel/tunnel_process.dart';
import 'package:passepartout/platform/tunnel/tunnel_protocol.dart';

void main() {
  test('protocol validates messages', () {
    expect(
      parseTunnelLine('{"type":"status","status":"connected"}')['status'],
      'connected',
    );
    expect(
      parseTunnelLine('{"type":"data","received":42,"sent":7}')['received'],
      42,
    );
    expect(
      parseTunnelLine('{"type":"error","code":"denied"}')['code'],
      'denied',
    );
    for (final line in [
      '[]',
      'oops',
      '{"type":"status","status":"oops"}',
      '{"type":"data","received":-1,"sent":0}',
      '{"type":"ready","pid":0}',
    ]) {
      expect(() => parseTunnelLine(line), throwsFormatException);
    }
  });
  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('tunnel-test-');
  });
  tearDown(() async {
    await temp.delete(recursive: true);
  });
  Future<String> helper(String body) async {
    final file = File('${temp.path}/fake.py');
    await file.writeAsString(body);
    return file.path;
  }

  test('private profile, stream, cleanup, duplicate guard and stop', () async {
    final report = '${temp.path}/report';
    final script = await helper('''
import sys,os,json
path=sys.argv[1]
with open(${jsonEncode(report)},'w') as out:
 json.dump({'path':path,'mode':os.stat(path).st_mode & 511,'parent':os.stat(os.path.dirname(path)).st_mode & 511,'profile':open(path).read()},out)
print(json.dumps({'type':'ready','pid':os.getpid()}),flush=True)
print('invalid',flush=True)
print(json.dumps({'type':'status','status':'connecting'}),flush=True)
print(json.dumps({'type':'data','received':100,'sent':25}),flush=True)
print('native log',file=sys.stderr,flush=True)
for line in sys.stdin:
 if line.strip()=='stop': break
''');
    final events = <Map<String, dynamic>>[];
    final logs = <String>[];
    final process = TunnelProcess('/usr/bin/python3', prefix: [script]);
    await process.start('{"secret":"test"}', events.add, logs.add);
    final recorded = jsonDecode(await File(report).readAsString());
    expect(recorded['mode'], 384);
    expect(recorded['parent'], 448);
    expect(recorded['profile'], '{"secret":"test"}');
    expect(await File(recorded['path'] as String).exists(), false);
    await expectLater(
      process.start('{}', events.add, logs.add),
      throwsStateError,
    );
    await process.stop();
    await process.stop();
    expect(
      events.any((e) => e['type'] == 'data' && e['received'] == 100),
      true,
    );
    expect(events.last['status'], 'disconnected');
    expect(logs, contains('native log'));
    expect(logs, contains('Invalid helper event'));
  });
  test('early exit deletes profile', () async {
    final report = '${temp.path}/path';
    final script = await helper(
      "import sys\nopen(${jsonEncode(report)},'w').write(sys.argv[1])\nsys.exit(7)\n",
    );
    final process = TunnelProcess('/usr/bin/python3', prefix: [script]);
    await expectLater(process.start('{}', (_) {}, (_) {}), throwsStateError);
    expect(await File(await File(report).readAsString()).exists(), false);
  });
  test('timeout sends stop', () async {
    final script = await helper(
      'import sys\nfor line in sys.stdin:\n if line.strip()=="stop": break\n',
    );
    final process = TunnelProcess(
      '/usr/bin/python3',
      prefix: [script],
      startTimeout: const Duration(milliseconds: 100),
    );
    await expectLater(
      process.start('{}', (_) {}, (_) {}),
      throwsA(isA<Exception>()),
    );
    await process.stop();
  });
}
