import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/dashboard.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/agents', [fakeAgent, fakeAgent2]);
    // Tasks and activities for each agent
    adapter.addResponse('GET', '/agents/agent-001/tasks', [fakeTask]);
    adapter.addResponse('GET', '/agents/agent-002/tasks', []);
    adapter.addResponse('GET', '/agents/agent-001/activity', [fakeActivity]);
    adapter.addResponse('GET', '/agents/agent-002/activity', []);
  });

  group('DashboardPage', () {
    testWidgets('shows greeting', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      // Greeting depends on time of day, just check it renders
      expect(find.textContaining('好'), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('shows agent count', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('2 位数字员工'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows new agent button', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('新建智能体'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows stats bar', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('数字员工'), findsOneWidget);
      expect(find.text('进行中任务'), findsOneWidget);
      expect(find.text('今日 Token'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows agent names', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('Assistant'), findsWidgets);
      expect(find.text('Researcher'), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('shows global activity section', (tester) async {
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('全局动态'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('empty state when no agents', (tester) async {
      adapter.addResponse('GET', '/agents', []);
      await pumpPage(tester, const DashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('还没有数字员工'), findsOneWidget);
      expect(find.text('创建第一个智能体'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows loading spinner initially', (tester) async {
      await pumpPage(tester, const DashboardPage());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await disposePage(tester);
    });
  });
}
