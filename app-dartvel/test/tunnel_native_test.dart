// SPDX-License-Identifier: GPL-3.0
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/platform/vpn_service_native.dart';

void main() {
  test('missing helper explains unavailable connection without losing native imports', () async {
    final engine = PartoutVpnService(
      helperPath: '/nonexistent/partout-tunnel-test',
    );
    expect(engine.canConnect, false);
    expect(engine.connectUnavailableReason, contains('helper'));
    final profile = await engine.importProfile(
      await File('test/fixtures/sample.conf').readAsString(),
      'Test',
    );
    expect(profile.name, 'Test');
    expect(profile.modules.map((m) => m.type), contains('WireGuard'));
    await expectLater(
      engine.connect(profile, onStatus: (_) {}),
      throwsUnsupportedError,
    );
    await engine.disconnect();
    final key = await engine.generateWireGuardKey();
    expect(key.length, 44);
    expect((await engine.wireGuardPublicKey(key)).length, 44);
  });
}
