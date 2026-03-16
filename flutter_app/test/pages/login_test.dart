import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/login.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnv();
  });

  group('LoginPage', () {
    testWidgets('shows app name', (tester) async {
      await pumpScaffoldedPage(tester, const LoginPage());
      await tester.pump();

      expect(find.text('OhClaw'), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('shows welcome text', (tester) async {
      await pumpScaffoldedPage(tester, const LoginPage());
      await tester.pump();

      expect(find.text('欢迎回来'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows Google sign-in button', (tester) async {
      await pumpScaffoldedPage(tester, const LoginPage());
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows privacy link', (tester) async {
      await pumpScaffoldedPage(tester, const LoginPage());
      await tester.pump();

      expect(find.text('隐私政策'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows security text', (tester) async {
      await pumpScaffoldedPage(tester, const LoginPage());
      await tester.pump();

      expect(find.text('安全登录'), findsOneWidget);

      await disposePage(tester);
    });
  });
}
