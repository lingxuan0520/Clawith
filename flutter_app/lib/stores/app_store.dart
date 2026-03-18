import 'dart:ui' show Brightness, Locale;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

// --- App-level state (sidebar, theme, tenant, locale) ---
class AppState {
  final bool sidebarCollapsed;
  final String? selectedAgentId;
  final String currentTenantId;
  final String themeMode; // 'system', 'dark', or 'light'
  final String? accentColor; // hex, e.g. '#5A96FF'
  final String locale; // 'zh' or 'en'

  const AppState({
    this.sidebarCollapsed = false,
    this.selectedAgentId,
    this.currentTenantId = '',
    this.themeMode = 'dark',
    this.accentColor,
    this.locale = 'zh',
  });

  Locale get flutterLocale => Locale(locale);

  AppState copyWith({
    bool? sidebarCollapsed,
    String? selectedAgentId,
    String? currentTenantId,
    String? themeMode,
    String? accentColor,
    String? locale,
    bool clearAgent = false,
    bool clearAccent = false,
  }) {
    return AppState(
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      selectedAgentId: clearAgent ? null : (selectedAgentId ?? this.selectedAgentId),
      currentTenantId: currentTenantId ?? this.currentTenantId,
      themeMode: themeMode ?? this.themeMode,
      accentColor: clearAccent ? null : (accentColor ?? this.accentColor),
      locale: locale ?? this.locale,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    _loadPrefs();
  }

  /// Test-only constructor that skips [_loadPrefs] and sets state directly.
  @visibleForTesting
  AppNotifier.seeded(super.initial);

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final collapsed = prefs.getBool('sidebar_collapsed') ?? false;
    final theme = prefs.getString('theme') ?? 'dark';
    final tenant = prefs.getString('current_tenant_id') ?? '';
    final accent = prefs.getString('accent_color');
    final locale = prefs.getString('locale') ?? 'zh';
    _syncAppColorsDark(theme);
    state = state.copyWith(
      sidebarCollapsed: collapsed,
      themeMode: theme,
      currentTenantId: tenant,
      accentColor: accent,
      locale: locale,
    );
  }

  /// Resolve effective dark/light from themeMode string and update AppColors.
  static void _syncAppColorsDark(String mode) {
    if (mode == 'system') {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      AppColors.setDark(brightness == Brightness.dark);
    } else {
      AppColors.setDark(mode == 'dark');
    }
  }

  void toggleSidebar() async {
    final next = !state.sidebarCollapsed;
    state = state.copyWith(sidebarCollapsed: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sidebar_collapsed', next);
  }

  void toggleTheme() async {
    final next = state.themeMode == 'dark' ? 'light' : 'dark';
    setThemeMode(next);
  }

  void setThemeMode(String mode) async {
    _syncAppColorsDark(mode);
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode);
  }

  void setTenant(String tenantId) async {
    state = state.copyWith(currentTenantId: tenantId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_tenant_id', tenantId);
  }

  void setSelectedAgent(String? id) {
    state = state.copyWith(selectedAgentId: id, clearAgent: id == null);
  }

  Future<void> setAccentColor(String? hex) async {
    state = state.copyWith(accentColor: hex, clearAccent: hex == null);
    final prefs = await SharedPreferences.getInstance();
    if (hex == null) {
      await prefs.remove('accent_color');
    } else {
      await prefs.setString('accent_color', hex);
    }
  }

  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});

/// Incremented each time the office tab becomes active, so OfficeWebViewPage
/// can refresh agent data.
final officeVisitCountProvider = StateProvider<int>((ref) => 0);
