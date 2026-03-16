import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/agent_create/agent_create_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/enterprise/llm-models', [fakeModel]);
    adapter.addResponse('GET', '/agents/templates', [fakeTemplate, fakeTemplate2]);
    adapter.addResponse('POST', '/agents', {'id': 'new-agent-001', 'name': 'Test'});
  });

  group('AgentCreatePage', () {
    testWidgets('shows app bar with title', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('招募新员工'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows step 0 card with basic info', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('基本信息与模型'), findsOneWidget);
      expect(find.text('Agent 名称 *'), findsOneWidget);
      expect(find.text('角色描述'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows model dropdowns', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('主模型 *'), findsOneWidget);
      expect(find.text('备用模型'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows step indicator', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('基本信息'), findsOneWidget);
      expect(find.text('性格设定'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows next button on step 0', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('下一步'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows template dropdown', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.text('模板'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows empty model hint when no models', (tester) async {
      adapter.addResponse('GET', '/enterprise/llm-models', []);
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      await tester.pumpAndSettle();

      expect(find.textContaining('请先前往'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await pumpScaffoldedPage(tester, const AgentCreatePage());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await disposePage(tester);
    });
  });
}
