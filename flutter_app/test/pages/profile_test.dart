import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/profile_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() async {
    await setupTestEnv();
  });

  group('ProfilePage', () {
    testWidgets('shows user display name', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.text('Test User'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows user role in Chinese', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.text('平台管理员'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows settings section', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.text('设置'), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('shows about section with privacy link', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.text('关于'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows account section with logout and delete', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.text('账号'), findsOneWidget);
      expect(find.text('退出登录'), findsOneWidget);
      expect(find.text('删除账号'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows theme toggle option', (tester) async {
      await pumpPage(tester, const ProfilePage());

      // Default is dark mode
      expect(find.text('切换到浅色模式'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('has logout icon', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.byIcon(Icons.logout), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('has delete icon', (tester) async {
      await pumpPage(tester, const ProfilePage());

      expect(find.byIcon(Icons.delete_forever), findsOneWidget);

      await disposePage(tester);
    });
  });
}
