// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/dartvel_client/dartvel_client.dart';
import 'package:passepartout/domain/profile.dart';
import 'package:passepartout/state/app_state.dart';
import 'package:passepartout/ui/screens/profiles_screen.dart';

import 'support/app_harness.dart';

void main() {
  setUp(setUpApp);

  testWidgets('profile list: empty state, then a profile row with its status', (tester) async {
    DV.global<ProfilesState>(const ProfilesState(isReady: true));
    await tester.pumpWidget(appUnderTest(const ProfilesScreen()));
    expect(find.text('Passepartout'), findsOneWidget);
    expect(find.text('No profiles'), findsOneWidget);

    DV.global<ProfilesState>(ProfilesState(isReady: true, profiles: <TunnelProfile>[TunnelProfile.empty('Office')]));
    await tester.pumpAndSettle();
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('No profile'), findsOneWidget); // installed header, nothing active
    expect(find.text('My profiles'.toUpperCase()), findsOneWidget);
  });
}
