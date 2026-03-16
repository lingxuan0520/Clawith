import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ohclaw/core/network/api_client.dart';
import 'package:ohclaw/core/theme/app_theme.dart';
import 'package:ohclaw/stores/auth_store.dart';
import 'package:ohclaw/stores/app_store.dart';

import 'fake_dio_adapter.dart';
import 'fake_data.dart';

export 'fake_dio_adapter.dart';
export 'fake_data.dart';

/// Default auth state used across tests.
final testAuthState = AuthState(
  token: 'fake-jwt-token',
  user: fakeUser,
  loading: false,
  initialized: true,
);

/// Default app state used across tests.
const testAppState = AppState(
  currentTenantId: 'tenant-001',
  themeMode: 'dark',
);

/// Sets up the test environment:
/// - SharedPreferences with mock values
/// - ApiClient with a [FakeDioAdapter] (interceptors cleared)
///
/// Returns the [FakeDioAdapter] so tests can configure responses.
Future<FakeDioAdapter> setupTestEnv() async {
  SharedPreferences.setMockInitialValues({
    'token': 'fake-jwt-token',
    'current_tenant_id': 'tenant-001',
    'theme_mode': 'dark',
  });

  final adapter = FakeDioAdapter();

  // Replace the HTTP adapter on the singleton Dio instance
  final dio = ApiClient.instance.dio;
  dio.httpClientAdapter = adapter;

  // Clear real interceptors (AuthInterceptor uses SharedPreferences async
  // which creates pending timers in the test zone)
  dio.interceptors.clear();

  // Pre-configure common responses
  adapter.addResponse('GET', '/auth/me', fakeUser);
  adapter.addResponse('GET', '/tenants', [fakeTenant]);
  adapter.addResponse('GET', '/agents', [fakeAgent, fakeAgent2]);

  return adapter;
}

/// Standard provider overrides for tests.
List<Override> testOverrides({AuthState? auth, AppState? app}) => [
  authProvider.overrideWith(
    (_) => AuthNotifier.seeded(auth ?? testAuthState),
  ),
  appProvider.overrideWith(
    (_) => AppNotifier.seeded(app ?? testAppState),
  ),
];

/// Dark theme matching the app for test rendering.
final testTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.bgPrimary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accentPrimary,
    surface: AppColors.bgPrimary,
  ),
);

/// Pumps a widget inside a [ProviderScope] + [MaterialApp] + [Scaffold] wrapper.
/// The [child] is placed in the Scaffold body.
Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(), ...overrides],
      child: MaterialApp(
        home: Scaffold(body: child),
        theme: testTheme,
      ),
    ),
  );
}

/// Pumps a widget that provides its own Scaffold (e.g. pages with AppBar).
Future<void> pumpScaffoldedPage(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(), ...overrides],
      child: MaterialApp(
        home: child,
        theme: testTheme,
      ),
    ),
  );
}

/// Disposes the current widget tree and flushes all pending microtasks/timers.
/// MUST be called at the END of every test that uses pages with periodic timers
/// or async initState (PlazaPage, ChatListPage, DashboardPage, MessagesPage, etc.).
Future<void> disposePage(WidgetTester tester) async {
  // First let any in-flight Dio zero-duration timers settle
  await tester.pumpAndSettle();
  // Replace widget tree to trigger dispose (cancels periodic timers)
  await tester.pumpWidget(const SizedBox());
  // Flush remaining microtasks/zero-duration timers from Dio async chains
  await tester.pumpAndSettle();
}
