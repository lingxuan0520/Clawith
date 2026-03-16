import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/chat/typing_dots.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TypingDots', () {
    testWidgets('renders 3 dot containers', (tester) async {
      await pumpPage(tester, const TypingDots());

      // Find the Row that is a direct descendant of TypingDots
      final rowFinder = find.descendant(
        of: find.byType(TypingDots),
        matching: find.byType(Row),
      );
      expect(rowFinder, findsOneWidget);

      final row = tester.widget<Row>(rowFinder);
      expect(row.children.length, 3);
    });

    testWidgets('uses AnimatedBuilder for animation', (tester) async {
      await pumpPage(tester, const TypingDots());

      // Find AnimatedBuilder within TypingDots specifically
      expect(
        find.descendant(of: find.byType(TypingDots), matching: find.byType(AnimatedBuilder)),
        findsOneWidget,
      );
    });

    testWidgets('animates without errors', (tester) async {
      await pumpPage(tester, const TypingDots());

      // Advance animation frames — should not throw
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TypingDots), findsOneWidget);
    });
  });
}
