import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/chat_list.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    // Default: return two agents
    adapter.addResponse('GET', '/agents', [fakeAgent, fakeAgent2]);
  });

  group('ChatListPage', () {
    testWidgets('shows header "聊天"', (tester) async {
      await pumpPage(tester, const ChatListPage());
      await tester.pump();

      expect(find.text('聊天'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows recruit button', (tester) async {
      await pumpPage(tester, const ChatListPage());
      await tester.pump();

      expect(find.byIcon(Icons.person_add_alt_1), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('renders agent list after loading', (tester) async {
      await pumpPage(tester, const ChatListPage());
      await tester.pumpAndSettle();

      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('Researcher'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows status indicators', (tester) async {
      await pumpPage(tester, const ChatListPage());
      await tester.pumpAndSettle();

      // Agent roles are shown as subtitles
      expect(find.text('AI 助手'), findsOneWidget);
      expect(find.text('研究员'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('empty state when no agents', (tester) async {
      adapter.addResponse('GET', '/agents', []);
      await pumpPage(tester, const ChatListPage());
      await tester.pumpAndSettle();

      expect(find.text('还没有 Agent'), findsOneWidget);
      expect(find.text('创建第一个 Agent'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows loading spinner initially', (tester) async {
      await pumpPage(tester, const ChatListPage());
      // Before API response arrives
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await disposePage(tester);
    });
  });
}
