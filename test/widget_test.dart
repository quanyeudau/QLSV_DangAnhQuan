// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:quanly_sv/main.dart';

void main() {
  testWidgets('App loads student screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Expect the app bar title
    expect(find.text('Quản lý sinh viên'), findsOneWidget);
    // Initial state: either loading or empty text appears eventually
    await tester.pump(const Duration(milliseconds: 500));
    // We don't assert data contents (DB may be empty), just ensure no crash.
  });
}
