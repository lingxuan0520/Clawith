import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/enterprise/enterprise_settings_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/enterprise/llm-models', [fakeModel]);
    adapter.addResponse('GET', '/tools', [fakeTool]);
    adapter.addResponse('GET', '/skills', [fakeSkill]);
    adapter.addResponse('GET', '/skills/browse/list', []);
  });

  group('EnterpriseSettingsPage', () {
    testWidgets('shows app bar with title', (tester) async {
      await pumpScaffoldedPage(tester, const EnterpriseSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows three tabs', (tester) async {
      await pumpScaffoldedPage(tester, const EnterpriseSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('模型池'), findsOneWidget);
      expect(find.text('工具'), findsOneWidget);
      expect(find.text('Skills'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows model data in first tab', (tester) async {
      await pumpScaffoldedPage(tester, const EnterpriseSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('GPT-4o'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows add model button', (tester) async {
      await pumpScaffoldedPage(tester, const EnterpriseSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('添加模型'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('empty state when no models', (tester) async {
      adapter.addResponse('GET', '/enterprise/llm-models', []);
      await pumpScaffoldedPage(tester, const EnterpriseSettingsPage());
      await tester.pumpAndSettle();

      expect(find.text('暂无模型配置'), findsOneWidget);

      await disposePage(tester);
    });
  });
}
