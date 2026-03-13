import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../stores/auth_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _googleLoading = false;
  bool _appleLoading = false;
  String _error = '';
  bool _googleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    } catch (_) {}
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _error = ''; _googleLoading = true; });
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null) throw Exception('Google did not return an ID token');

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseIdToken = await userCredential.user!.getIdToken();
      await _exchangeToken(firebaseIdToken!);
    } catch (e) {
      if (e.toString().contains('canceled') || e.toString().contains('sign_in_canceled')) {
        setState(() => _googleLoading = false);
        return;
      }
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _error = ''; _appleLoading = true; });
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final firebaseIdToken = await userCredential.user!.getIdToken();
      await _exchangeToken(firebaseIdToken!);
    } catch (e) {
      if (e.toString().contains('canceled') || e.toString().contains('AuthorizationCanceled')) {
        setState(() => _appleLoading = false);
        return;
      }
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  Future<void> _exchangeToken(String idToken) async {
    final res = await ApiService.instance.loginWithFirebase(idToken);
    final user = res['user'] as Map<String, dynamic>;
    final token = res['access_token'] as String;
    await ref.read(authProvider.notifier).setAuth(user, token);
    if (mounted) context.go('/plaza');
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS || Platform.isMacOS;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              // Left hero panel (only on wide screens)
              if (isWide)
                Expanded(
                  flex: 5,
                  child: Container(
                    color: const Color(0xFF0A0D14),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.statusRunning,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('你的专属 AI 公司',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Soloship',
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1)),
                        const Text('一个人的公司',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        const Text('AI 员工为你全天候工作，\n无需发工资。',
                            style: TextStyle(fontSize: 15, color: AppColors.textTertiary, height: 1.6)),
                        const SizedBox(height: 40),
                        _heroFeature('🤖', 'AI 员工', '雇佣、配置和部署 AI 员工'),
                        const SizedBox(height: 16),
                        _heroFeature('🧠', '持久记忆', '他们能学习、记忆和成长'),
                        const SizedBox(height: 16),
                        _heroFeature('🚀', '独立运营', '扩展你的一人公司'),
                      ],
                    ),
                  ),
                ),
              // Right form panel
              Expanded(
                flex: 4,
                child: Container(
                  color: AppColors.bgSecondary,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                Text('🚢', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 8),
                                Text('Soloship', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text('欢迎回来',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            const Text('登录以管理你的 AI 团队。',
                                style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                            const SizedBox(height: 32),
                            if (_error.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Text('⚠ $_error', style: const TextStyle(color: AppColors.error, fontSize: 13)),
                              ),
                            // Google Sign-in
                            _SignInButton(
                              onTap: (_googleLoading || _appleLoading) ? null : _signInWithGoogle,
                              loading: _googleLoading,
                              icon: _GoogleIcon(),
                              label: 'Continue with Google',
                            ),
                            // Apple Sign-in (only on iOS/macOS)
                            if (isIOS) ...[
                              const SizedBox(height: 12),
                              _SignInButton(
                                onTap: (_googleLoading || _appleLoading) ? null : _signInWithApple,
                                loading: _appleLoading,
                                icon: const Icon(Icons.apple, size: 20, color: AppColors.textPrimary),
                                label: 'Continue with Apple',
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('安全登录', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 12, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  isIOS ? '由 Google 与 Apple 提供安全登录' : '由 Google 提供安全登录',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => context.push('/privacy'),
                              child: const Text(
                                '隐私政策',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroFeature(String emoji, String title, String desc) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final Widget icon;
  final String label;

  const _SignInButton({required this.onTap, required this.loading, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderSubtle),
          backgroundColor: AppColors.bgTertiary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: const Center(
        child: Text('G', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
      ),
    );
  }
}
