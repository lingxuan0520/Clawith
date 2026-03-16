import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/privacy_policy.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PrivacyPolicyPage', () {
    testWidgets('renders title and sections', (tester) async {
      await pumpScaffoldedPage(tester, const PrivacyPolicyPage());

      expect(find.text('隐私政策'), findsOneWidget);
      expect(find.text('OhClaw 隐私政策'), findsOneWidget);
      expect(find.text('1. 我们收集的信息'), findsOneWidget);
      expect(find.text('2. 我们如何使用信息'), findsOneWidget);
      expect(find.text('3. AI 对话数据'), findsOneWidget);
      expect(find.text('4. 数据存储与安全'), findsOneWidget);
      expect(find.text('5. 数据删除'), findsOneWidget);
      expect(find.text('6. 第三方服务'), findsOneWidget);
      expect(find.text('7. 儿童隐私'), findsOneWidget);
      expect(find.text('8. 隐私政策变更'), findsOneWidget);
      expect(find.text('9. 联系我们'), findsOneWidget);
    });

    testWidgets('has back button', (tester) async {
      await pumpScaffoldedPage(tester, const PrivacyPolicyPage());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows last updated date', (tester) async {
      await pumpScaffoldedPage(tester, const PrivacyPolicyPage());

      expect(find.textContaining('最后更新：2026'), findsOneWidget);
    });
  });
}
