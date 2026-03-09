import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clawith/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClawithApp()));
    expect(find.byType(ClawithApp), findsOneWidget);
  });
}
