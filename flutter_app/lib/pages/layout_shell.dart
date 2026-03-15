import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../core/app_lifecycle.dart';

class LayoutShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const LayoutShell({super.key, required this.navigationShell});
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
        if (appState.currentTenantId.isEmpty || !tenantIds.contains(appState.currentTenantId)) {
          final fallback = data.first['id'] as String;
          ref.read(appProvider.notifier).setTenant(fallback);
        }
      }
    } catch (_) {}
  }

  // Map branch index to the 4 main tabs (0-3)
  int get _tabIndex {
    final idx = widget.navigationShell.currentIndex;
    return idx < 4 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(child: widget.navigationShell),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => widget.navigationShell.goBranch(i, initialLocation: i == widget.navigationShell.currentIndex),
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
