import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../core/app_lifecycle.dart';

class LayoutShell extends ConsumerStatefulWidget {
  final Widget child;
  const LayoutShell({super.key, required this.child});
  @override
  ConsumerState<LayoutShell> createState() => _LayoutShellState();
}

class _LayoutShellState extends ConsumerState<LayoutShell> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _ensureTenantLoaded();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!AppLifecycle.instance.isActive) return;
    });
  }

  Future<void> _ensureTenantLoaded() async {
    try {
      final data = await ApiService.instance.listTenants();
      if (mounted && data.isNotEmpty) {
        final appState = ref.read(appProvider);
        final tenantIds = data.map((t) => t['id'] as String).toSet();
        // Reset if no tenant selected or if cached tenant doesn't belong to current user
        if (appState.currentTenantId.isEmpty || !tenantIds.contains(appState.currentTenantId)) {
          final fallback = data.first['id'] as String;
          ref.read(appProvider.notifier).setTenant(fallback);
        }
      }
    } catch (_) {}
  }

  int _currentIndex(String location) {
    if (location.startsWith('/chat-list')) return 1;
    if (location.startsWith('/office')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // /plaza or default
  }

  static const _tabs = [
    '/plaza',
    '/chat-list',
    '/office',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final currentIdx = _currentIndex(currentLocation);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: widget.child),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: currentIdx,
          onTap: (i) {
            if (i != currentIdx) {
              context.go(_tabs[i]);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bgSecondary,
          selectedItemColor: AppColors.accentPrimary,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.workspaces), label: '工作台'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '聊天'),
            BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: '办公室'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
