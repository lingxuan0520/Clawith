import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

// --- Auth State ---
class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool loading;
  final bool initialized; // true after first token check from SharedPreferences

  const AuthState({this.token, this.user, this.loading = false, this.initialized = false});

  bool get isAuthenticated => token != null;
  String get userId => user?['id'] ?? '';
  String get username => user?['username'] ?? '';
  String get displayName => user?['display_name'] ?? '';
  String get role => user?['role'] ?? 'member';
  String? get tenantId => user?['tenant_id'];
  bool get isPlatformAdmin => role == 'platform_admin';
  bool get isOrgAdmin => role == 'org_admin';
  bool get isAdmin => isPlatformAdmin || isOrgAdmin;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? loading,
    bool? initialized,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadToken();
  }

  /// Test-only constructor that skips [_loadToken] and sets state directly.
  @visibleForTesting
  AuthNotifier.seeded(super.initial);

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = state.copyWith(token: token, loading: true);
      try {
        final user = await ApiService.instance.getMe();
        state = state.copyWith(user: user, loading: false, initialized: true);
      } catch (e) {
        await _clearAuth(prefs);
        state = AuthState(initialized: true);
      }
    } else {
      state = state.copyWith(initialized: true);
    }
  }

  Future<void> setAuth(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    state = AuthState(token: token, user: user, initialized: true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearAuth(prefs);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    state = AuthState(initialized: true);
  }

  Future<void> _clearAuth(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('current_tenant_id');
  }

  void updateUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
