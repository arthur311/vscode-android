import 'package:flutter_test/flutter_test.dart';

import 'package:vscode_android/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VSCodeAndroidApp());
    expect(find.byType(VSCodeAndroidApp), findsOneWidget);
  });
}
