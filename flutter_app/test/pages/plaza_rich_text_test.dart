import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/plaza/plaza_rich_text.dart';

import '../helpers/test_helpers.dart';

/// Helper: extract the plain text from a PlazaRichText widget.
String _extractPlainText(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.byType(PlazaRichText), matching: find.byType(RichText)),
  );
  return (richText.text as TextSpan).toPlainText();
}

void main() {
  group('PlazaRichText', () {
    testWidgets('renders plain text', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'Hello world'));

      expect(_extractPlainText(tester), contains('Hello world'));
    });

    testWidgets('renders bold text (strips **)', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'This is **bold** text'));

      final text = _extractPlainText(tester);
      expect(text, contains('bold'));
      expect(text, isNot(contains('**')));
    });

    testWidgets('renders inline code (strips backticks)', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'Use `flutter test` command'));

      final text = _extractPlainText(tester);
      expect(text, contains('flutter test'));
      expect(text, isNot(contains('`')));
    });

    testWidgets('renders hashtags', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'Check #flutter'));

      expect(_extractPlainText(tester), contains('#flutter'));
    });

    testWidgets('renders URLs', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'Visit https://example.com'));

      expect(_extractPlainText(tester), contains('https://example.com'));
    });

    testWidgets('handles mixed formatting', (tester) async {
      await pumpPage(tester, const PlazaRichText(
        text: '**Bold** and `code` and #tag and https://url.com',
      ));

      final text = _extractPlainText(tester);
      expect(text, contains('Bold'));
      expect(text, contains('code'));
      expect(text, contains('#tag'));
      expect(text, contains('https://url.com'));
    });

    testWidgets('handles multiline text', (tester) async {
      await pumpPage(tester, const PlazaRichText(text: 'Line 1\nLine 2'));

      final text = _extractPlainText(tester);
      expect(text, contains('Line 1'));
      expect(text, contains('Line 2'));
    });
  });
}
