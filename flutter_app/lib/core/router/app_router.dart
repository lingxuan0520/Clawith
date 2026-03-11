import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../stores/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../pages/login.dart';
import '../../pages/layout_shell.dart';
import '../../pages/dashboard.dart';
import '../../pages/plaza.dart';
import '../../pages/agent_create.dart';
import '../../pages/agent_detail.dart';
import '../../pages/chat.dart';
import '../../pages/messages.dart';
import '../../pages/enterprise_settings.dart';
import '../../pages/invitation_codes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Still initializing — stay on or go to splash
      if (!authState.initialized) {
        return location == '/splash' ? null : '/splash';
      }

      // Initialized — never stay on splash
      final isLoggedIn = authState.token != null;
      if (location == '/splash') {
        return isLoggedIn ? '/plaza' : '/login';
      }

      final isLoginRoute = location == '/login';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/plaza';
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
      ShellRoute(
        builder: (context, state, child) => LayoutShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/plaza',
            builder: (context, state) => const PlazaPage(),
          ),
          GoRoute(
            path: '/agents/new',
            builder: (context, state) => const AgentCreatePage(),
          ),
          GoRoute(
            path: '/agents/:id',
            builder: (context, state) =>
                AgentDetailPage(agentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/agents/:id/chat',
            builder: (context, state) =>
                ChatPage(agentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: '/enterprise',
            builder: (context, state) => const EnterpriseSettingsPage(),
          ),
          GoRoute(
            path: '/invitations',
            builder: (context, state) => const InvitationCodesPage(),
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
      ),
    );
  }
}
