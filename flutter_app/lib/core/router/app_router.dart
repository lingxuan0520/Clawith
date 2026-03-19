import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../stores/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../pages/login.dart';
import '../../pages/layout_shell.dart';
import '../../pages/home_page.dart';
import '../../pages/chat_list.dart';
import '../../pages/profile_page.dart';
import '../../pages/agent_create.dart';
import '../../pages/agent_detail/agent_detail_page.dart';
import '../../pages/chat.dart';
import '../../pages/messages.dart';
import '../../pages/enterprise/enterprise_settings_page.dart';
import '../../pages/invitation_codes.dart';
import '../../game/office_webview_page.dart';
import '../../pages/privacy_policy.dart';
import '../../pages/onboarding.dart';
import '../../pages/billing_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!authState.initialized) {
        return location == '/splash' ? null : '/splash';
      }

      final isLoggedIn = authState.token != null;
      if (location == '/splash') {
        return isLoggedIn ? '/plaza' : '/login';
      }

      final isPublicRoute = location == '/login' || location == '/privacy';
      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && location == '/login') return '/plaza';
      if (isLoggedIn && location == '/onboarding') return null;
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Full-screen routes outside tab shell
      GoRoute(
        path: '/agents/new',
        builder: (context, state) => const AgentCreatePage(),
      ),
      GoRoute(
        path: '/agents/:id',
        builder: (context, state) =>
            AgentDetailPage(
              agentId: state.pathParameters['id']!,
              initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
            ),
      ),
      GoRoute(
        path: '/agents/:id/chat',
        builder: (context, state) =>
            ChatPage(agentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      // Enterprise settings — pushed from profile, has own back button
      GoRoute(
        path: '/enterprise',
        builder: (context, state) => const EnterpriseSettingsPage(),
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) => const BillingPage(),
      ),
      // Bottom tab shell — StatefulShellRoute keeps tab pages alive
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            LayoutShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/plaza',
              pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat-list',
              pageBuilder: (context, state) => const NoTransitionPage(child: ChatListPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/office',
              pageBuilder: (context, state) => const NoTransitionPage(child: OfficeWebViewPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              pageBuilder: (context, state) => const NoTransitionPage(child: MessagesPage()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/invitations',
              pageBuilder: (context, state) => const NoTransitionPage(child: InvitationCodesPage()),
            ),
          ]),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
      ),
    );
  }
}
