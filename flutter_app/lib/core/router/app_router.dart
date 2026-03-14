import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../stores/auth_store.dart';
import '../../core/theme/app_theme.dart';
import '../../pages/login.dart';
import '../../pages/layout_shell.dart';
import '../../pages/dashboard.dart';
import '../../pages/plaza.dart';
import '../../pages/chat_list.dart';
import '../../pages/profile_page.dart';
import '../../pages/agent_create.dart';
import '../../pages/agent_detail.dart';
import '../../pages/chat.dart';
import '../../pages/messages.dart';
import '../../pages/enterprise_settings.dart';
import '../../pages/invitation_codes.dart';
import '../../game/office_page.dart';
import '../../pages/privacy_policy.dart';

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
      // Full-screen routes outside tab shell
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
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      // Enterprise settings — pushed from profile, has own back button
      GoRoute(
        path: '/enterprise',
        builder: (context, state) => const EnterpriseSettingsPage(),
      ),
      // Bottom tab shell
      ShellRoute(
        builder: (context, state, child) => LayoutShell(child: child),
        routes: [
          GoRoute(
            path: '/plaza',
            builder: (context, state) => const PlazaPage(),
          ),
          GoRoute(
            path: '/chat-list',
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: '/office',
            builder: (context, state) => const OfficePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          // Keep dashboard accessible
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesPage(),
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
