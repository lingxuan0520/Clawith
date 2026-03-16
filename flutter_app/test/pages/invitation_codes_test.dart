import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/invitation_codes.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/enterprise/system-settings/invitation_code_enabled', {'value': {'enabled': false}});
    adapter.addResponse('GET', '/enterprise/invitation-codes', {
      'items': [fakeInvitationCode],
      'total': 1,
    });
    adapter.addResponse('POST', '/enterprise/invitation-codes', {});
    adapter.addResponse('PUT', '/enterprise/system-settings/invitation_code_enabled', {});
  });

  group('InvitationCodesPage', () {
    testWidgets('shows title', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pump();

      expect(find.text('邀请码'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows toggle section', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pump();

      expect(find.text('Require Invitation Code for Registration'), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows batch create section', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pump();

      expect(find.text('创建邀请码'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows codes table header', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pump();

      expect(find.text('CODE'), findsOneWidget);
      expect(find.text('USAGE'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows code data after loading', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pumpAndSettle();

      expect(find.text('ABCDEF'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows search field', (tester) async {
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pump();

      expect(find.byType(TextField), findsWidgets);

      await disposePage(tester);
    });

    testWidgets('empty state when no codes', (tester) async {
      adapter.addResponse('GET', '/enterprise/invitation-codes', {'items': [], 'total': 0});
      await pumpPage(tester, const InvitationCodesPage());
      await tester.pumpAndSettle();

      expect(find.text('No data'), findsOneWidget);

      await disposePage(tester);
    });
  });
}
