import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- App-level state (sidebar, theme, tenant) ---
class AppState {
  final bool sidebarCollapsed;
  final String? selectedAgentId;
  final String currentTenantId;
  final String themeMode; // 'dark' or 'light'

  const AppState({
    this.sidebarCollapsed = false,
    this.selectedAgentId,
    this.currentTenantId = '',
    this.themeMode = 'dark',
  });

  AppState copyWith({
    bool? sidebarCollapsed,
    String? selectedAgentId,
    String? currentTenantId,
    String? themeMode,
    bool clearAgent = false,
  }) {
    return AppState(
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      selectedAgentId: clearAgent ? null : (selectedAgentId ?? this.selectedAgentId),
      currentTenantId: currentTenantId ?? this.currentTenantId,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final collapsed = prefs.getBool('sidebar_collapsed') ?? false;
    final theme = prefs.getString('theme') ?? 'dark';
    final tenant = prefs.getString('current_tenant_id') ?? '';
    state = state.copyWith(
      sidebarCollapsed: collapsed,
      themeMode: theme,
      currentTenantId: tenant,
    );
  }

  void toggleSidebar() async {
    final next = !state.sidebarCollapsed;
    state = state.copyWith(sidebarCollapsed: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_collapsed', next);
  }

  void toggleTheme() async {
    final next = state.themeMode == 'dark' ? 'light' : 'dark';
    state = state.copyWith(themeMode: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', next);
  }

  void setTenant(String tenantId) async {
    state = state.copyWith(currentTenantId: tenantId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_tenant_id', tenantId);
  }

  void setSelectedAgent(String? id) {
    state = state.copyWith(selectedAgentId: id, clearAgent: id == null);
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
