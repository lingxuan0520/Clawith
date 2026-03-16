import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohclaw/pages/chat/chat_page.dart';

import '../helpers/test_helpers.dart';

void main() {
  late FakeDioAdapter adapter;

  setUp(() async {
    adapter = await setupTestEnv();
    adapter.addResponse('GET', '/agents/agent-001', fakeAgent);
    adapter.addResponse('GET', '/enterprise/llm-models', [fakeModel]);
    adapter.addResponse('GET', '/agents/agent-001/sessions', [fakeSession]);
    adapter.addResponse('POST', '/agents/agent-001/sessions', fakeSession);
    adapter.addResponse('GET', '/agents/agent-001/sessions/session-001/messages', [
      fakeAssistantMessage,
      fakeMessage,
    ]);
  });

  group('ChatPage', () {
    testWidgets('shows agent name in app bar', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const ChatPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assistant'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows input area with text field', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const ChatPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows send button', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const ChatPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.text('发送'), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows back button', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const ChatPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await disposePage(tester);
    });

    testWidgets('shows detail button in app bar', (tester) async {
      await pumpScaffoldedPage(
        tester,
        const ChatPage(agentId: 'agent-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await disposePage(tester);
    });
  });
}
