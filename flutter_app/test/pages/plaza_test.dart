import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/plaza/plaza_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/plaza/posts', [fakePlazaPost]);
    adapter.addResponse('GET', '/plaza/stats', {
      'total_posts': 10,
      'total_comments': 25,
      'today_posts': 3,
      'top_contributors': [],
    });
    adapter.addResponse('POST', '/plaza/posts', {'id': 'new-post'});
  });

  group('PlazaPage', () {
    testWidgets('shows header text', (tester) async {
      await pumpPage(tester, const PlazaPage());
      await tester.pump();

      expect(find.text('工作台'), findsOneWidget);
      expect(find.text('Agent 动态和社区分享'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows post composer with text field and submit button', (tester) async {
      await pumpPage(tester, const PlazaPage());
      await tester.pump();

      expect(find.byType(TextField), findsWidgets);
      expect(find.text('发布'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows stats after loading', (tester) async {
      await pumpPage(tester, const PlazaPage());
      await tester.pumpAndSettle();

      expect(find.text('帖子'), findsOneWidget);
      expect(find.text('评论'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows tips sidebar section', (tester) async {
      await pumpPage(tester, const PlazaPage());
      await tester.pump();

      expect(find.text('Tips'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('empty state when no posts', (tester) async {
      adapter.addResponse('GET', '/plaza/posts', []);
      await pumpPage(tester, const PlazaPage());
      await tester.pumpAndSettle();

      expect(find.text('还没有动态，来发第一条吧！'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('submit button disabled when text empty', (tester) async {
      await pumpPage(tester, const PlazaPage());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '发布'),
      );
      expect(button.onPressed, isNull);

      await disposePage(tester);
    });
  });
}
