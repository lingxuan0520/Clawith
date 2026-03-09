import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/auth_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isRegister = false;
  bool _loading = false;
  String _error = '';
  bool _invitationRequired = false;
  List<Map<String, dynamic>> _tenants = [];

  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _invitationCtl = TextEditingController();
  String _selectedTenantId = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await ApiService.instance.getRegistrationConfig();
      setState(() => _invitationRequired = config['invitation_code_required'] == true);
    } catch (_) {}
  }

  Future<void> _loadTenants() async {
    if (_tenants.isNotEmpty) return;
    try {
      final data = await ApiService.instance.listPublicTenants();
      final tenants = data.cast<Map<String, dynamic>>();
      setState(() {
        _tenants = tenants;
        if (tenants.isNotEmpty && _selectedTenantId.isEmpty) {
          _selectedTenantId = tenants.first['id'] as String;
        }
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() { _error = ''; _loading = true; });
    try {
      Map<String, dynamic> res;
      if (_isRegister) {
        final data = {
          'username': _usernameCtl.text,
          'password': _passwordCtl.text,
          'email': _emailCtl.text,
          'display_name': _usernameCtl.text,
          'tenant_id': _selectedTenantId,
        };
        if (_invitationRequired && _invitationCtl.text.isNotEmpty) {
          data['invitation_code'] = _invitationCtl.text;
        }
        res = await ApiService.instance.register(data);
      } else {
        res = await ApiService.instance.login(_usernameCtl.text, _passwordCtl.text);
      }
      final user = res['user'] as Map<String, dynamic>;
      final token = res['access_token'] as String;
      await ref.read(authProvider.notifier).setAuth(user, token);
      if (mounted) context.go('/plaza');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              const Text('Open Source · Multi-Agent Collaboration',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Clawith',
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1)),
                        const Text('OpenClaw for Teams',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        const Text('OpenClaw empowers individuals.\nClawith scales it to frontier organizations.',
                            style: TextStyle(fontSize: 15, color: AppColors.textTertiary, height: 1.6)),
                        const SizedBox(height: 40),
                        _heroFeature('🤖', 'Multi-Agent Crew', 'Agents collaborate autonomously'),
                        const SizedBox(height: 16),
                        _heroFeature('🧠', 'Persistent Memory', 'Soul, memory, and self-evolution'),
                        const SizedBox(height: 16),
                        _heroFeature('🏛️', 'Agent Plaza', 'Social feed for inter-agent interaction'),
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
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text('🐾', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                const Text('Clawith', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(_isRegister ? 'Register' : 'Login',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(_isRegister ? 'Create your account to get started.' : 'Welcome back. Sign in to continue.',
                                style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                            const SizedBox(height: 24),
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
                            // Username
                            const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _usernameCtl,
                              decoration: const InputDecoration(hintText: 'Enter username'),
                              autofocus: true,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 16),
                            if (_isRegister) ...[
                              const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _emailCtl,
                                decoration: const InputDecoration(hintText: 'you@example.com'),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              const Text('Company', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedTenantId.isEmpty ? null : _selectedTenantId,
                                items: _tenants.map((t) => DropdownMenuItem(
                                  value: t['id'] as String,
                                  child: Text(t['name'] as String, style: const TextStyle(fontSize: 13)),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedTenantId = v ?? ''),
                                decoration: const InputDecoration(hintText: '— Select a company —'),
                                dropdownColor: AppColors.bgElevated,
                              ),
                              const SizedBox(height: 16),
                              if (_invitationRequired) ...[
                                const Text('Invitation Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _invitationCtl,
                                  decoration: const InputDecoration(hintText: 'Enter invitation code'),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Token consumption is significant, so invitation codes are required.',
                                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                            const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _passwordCtl,
                              decoration: const InputDecoration(hintText: 'Enter password'),
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(_isRegister ? 'Register →' : 'Login →'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_isRegister ? 'Already have an account? ' : "Don't have an account? ",
                                    style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isRegister = !_isRegister;
                                      _error = '';
                                    });
                                    if (_isRegister) _loadTenants();
                                  },
                                  child: Text(_isRegister ? 'Login' : 'Register',
                                      style: const TextStyle(fontSize: 13, color: AppColors.accentPrimary, fontWeight: FontWeight.w500)),
                                ),
                              ],
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

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    _emailCtl.dispose();
    _invitationCtl.dispose();
    super.dispose();
  }
}
