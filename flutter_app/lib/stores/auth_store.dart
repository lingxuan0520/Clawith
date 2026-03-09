import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

// --- Auth State ---
class AuthState {
  final String? token;
  final Map<String, dynamic>? user;
  final bool loading;

  const AuthState({this.token, this.user, this.loading = false});

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
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return AuthState(
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = state.copyWith(token: token, loading: true);
      try {
        final user = await ApiService.instance.getMe();
        state = state.copyWith(user: user, loading: false);
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> setAuth(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    state = AuthState(token: token, user: user);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    state = const AuthState();
  }

  void updateUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
