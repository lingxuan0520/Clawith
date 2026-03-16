import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/onboarding.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('POST', '/tenants', {'id': 'new-tenant', 'name': 'My Co'});
    adapter.addResponse('GET', '/auth/me', fakeUser);
    adapter.addResponse('GET', '/agents/templates', [fakeTemplate, fakeTemplate2]);
    adapter.addResponse('POST', '/agents', {'id': 'new-agent', 'name': 'Test'});
  });

  group('OnboardingPage', () {
    testWidgets('shows welcome text on first step', (tester) async {
      await pumpScaffoldedPage(tester, const OnboardingPage());
      await tester.pumpAndSettle();

      expect(find.text('欢迎来到 OhClaw'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows create company button', (tester) async {
      await pumpScaffoldedPage(tester, const OnboardingPage());
      await tester.pumpAndSettle();

      expect(find.text('创建公司'), findsOneWidget);

      await disposePage(tester);
    });
  });
}
