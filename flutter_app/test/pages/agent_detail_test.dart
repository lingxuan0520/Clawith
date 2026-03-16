import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/agent_detail/agent_detail_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    // Core agent data
    adapter.addResponse('GET', '/agents/agent-001', fakeAgent);
    // Overview data
    adapter.addResponse('GET', '/agents/agent-001/metrics', fakeMetrics);
    adapter.addResponse('GET', '/agents/agent-001/activity', [fakeActivity]);
    // Tasks
    adapter.addResponse('GET', '/agents/agent-001/tasks', [fakeTask]);
    adapter.addResponse('GET', '/agents/agent-001/schedules', []);
    // Mind (soul.md etc)
    adapter.addResponse('GET', '/agents/agent-001/files/content', '');
    adapter.addResponse('GET', '/agents/agent-001/files', []);
    // Tools
    adapter.addResponse('GET', '/tools/agents/agent-001/with-config', [fakeTool]);
    adapter.addResponse('GET', '/tools/agents/agent-001', [fakeTool]);
    // Skills
    adapter.addResponse('GET', '/skills', [fakeSkill]);
    // Settings
    adapter.addResponse('GET', '/enterprise/llm-models', [fakeModel]);
    adapter.addResponse('GET', '/agents/agent-001/channel', fakeChannel);
  });

  group('AgentDetailPage', () {
    testWidgets('shows agent name in app bar', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const AgentDetailPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assistant'), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('shows all 8 tab labels', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const AgentDetailPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.text('状态'), findsOneWidget);
      expect(find.text('任务'), findsOneWidget);
      expect(find.text('思维'), findsOneWidget);
      expect(find.text('工具'), findsOneWidget);
      expect(find.text('技能'), findsOneWidget);
      expect(find.text('工作区'), findsOneWidget);
      expect(find.text('活动'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const AgentDetailPage(agentId: 'agent-001'),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows retry button on error', (tester) async {
      adapter.addError('GET', '/agents/agent-999');
      await pumpScaffoldedPage(
        tester,
        const AgentDetailPage(agentId: 'agent-999'),
      );
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await disposePage(tester);
    });
  });
}
