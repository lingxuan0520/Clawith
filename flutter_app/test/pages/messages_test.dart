import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/messages.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/messages/inbox', [fakeInboxMessage, fakeInboxMessageRead]);
    adapter.addResponse('GET', '/messages/unread-count', {'count': 1});
  });

  group('MessagesPage', () {
    testWidgets('shows header "消息"', (tester) async {
      await pumpPage(tester, const MessagesPage());
      await tester.pump();

      expect(find.text('消息'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows messages after loading', (tester) async {
      await pumpPage(tester, const MessagesPage());
      await tester.pumpAndSettle();

      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('任务已完成'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows mark all read button when unread exist', (tester) async {
      await pumpPage(tester, const MessagesPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('全部标为已读'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('empty state when no messages', (tester) async {
      adapter.addResponse('GET', '/messages/inbox', []);
      await pumpPage(tester, const MessagesPage());
      await tester.pumpAndSettle();

      expect(find.text('暂无消息'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows loading spinner initially', (tester) async {
      await pumpPage(tester, const MessagesPage());
      // Before API returns
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows both read and unread messages', (tester) async {
      await pumpPage(tester, const MessagesPage());
      await tester.pumpAndSettle();

      // Both messages should appear
      expect(find.text('任务已完成'), findsOneWidget);
      expect(find.text('报告已生成'), findsOneWidget);

      await disposePage(tester);
    });
  });
}
