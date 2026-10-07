import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passepartout/main.dart';

void main() {
  testWidgets('Dartvel application starts', (WidgetTester tester) async {
    // Generated pages are deferred, and loadLibrary() resolves on the real
    // event loop rather than the fake one a widget test runs on. Pumping
    // inside runAsync lets that finish; a plain pumpWidget leaves its timer
    // pending and fails the test rather than the app.
    await tester.runAsync(() async {
      await tester.pumpWidget(createDartvelApp());
      await tester.pump();
    });

    expect(find.byType(WidgetsApp), findsOneWidget);
  });
}
