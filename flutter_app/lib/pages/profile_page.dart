import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../stores/auth_store.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../components/initial_avatar.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final data = await ApiService.instance.getBillingBalance();
      if (mounted) setState(() => _balance = data);
    } catch (_) {}
  }
  Future<void> _confirmDeleteAccount() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(l.profileDeleteConfirmTitle, style: const TextStyle(color: AppColors.error)),
        content: Text(
          l.profileDeleteConfirmBody,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonConfirm, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService.instance.deleteAccount();
      if (!mounted) return;
      final nav = GoRouter.of(context);
      await ref.read(authProvider.notifier).logout();
      if (mounted) nav.go('/login');
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.profileDeleteFailed(e.toString()))),
        );
      }
    }
  }

  String _roleLabel(String role, AppLocalizations l) {
    switch (role) {
      case 'platform_admin': return l.profileRolePlatformAdmin;
      case 'org_admin': return l.profileRoleOrgAdmin;
      case 'agent_admin': return l.profileRoleAgentAdmin;
      default: return l.profileRoleMember;
    }
  }

  String _themeLabel(String mode, AppLocalizations l) {
    switch (mode) {
      case 'light': return l.profileThemeLight;
      case 'system': return l.profileThemeSystem;
      default: return l.profileThemeDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final appState = ref.watch(appProvider);
    final l = AppLocalizations.of(context)!;
    String? avatarUrl = (auth.user?['avatar_url'] as String?)?.isNotEmpty == true
        ? auth.user!['avatar_url'] as String
        : null;
    if (avatarUrl == null) {
      try {
        avatarUrl = fb.FirebaseAuth.instance.currentUser?.photoURL;
      } catch (_) {
        // Firebase may not be initialized (e.g. in tests)
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // User header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(avatarUrl, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => InitialAvatar(name: auth.displayName, size: 56, fontSize: 22, borderRadius: 16))
                    : InitialAvatar(name: auth.displayName, size: 56, fontSize: 22, borderRadius: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_roleLabel(auth.role, l),
                        style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Balance card
        if (_balance != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => context.push('/billing'),
              child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accentPrimary.withValues(alpha: 0.15), AppColors.bgElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentPrimary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('余额',
                            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        const SizedBox(height: 2),
                        Text(
                          '\$${((_balance!['credit_balance_cents'] as int? ?? 0) / 100).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('已消费',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Text(
                        '\$${((_balance!['total_used_cents'] as int? ?? 0) / 100).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Settings section
        _sectionHeader(l.profileSettings),
        _menuItem(
          icon: Icons.settings,
          label: l.profileSettings,
          onTap: () => context.push('/enterprise'),
        ),
        _menuItem(
          icon: _themeIcon(appState.themeMode),
          label: l.profileTheme(_themeLabel(appState.themeMode, l)),
          onTap: () => _showThemePicker(context, ref, appState.themeMode, l),
        ),
        _menuItem(
          icon: Icons.language,
          label: l.profileLanguage(appState.locale == 'zh' ? l.profileLangZh : l.profileLangEn),
          onTap: () => _showLanguageDialog(context, ref, l),
        ),
        const SizedBox(height: 16),

        // About section
        _sectionHeader(l.profileAbout),
        _menuItem(
          icon: Icons.privacy_tip_outlined,
          label: l.profilePrivacyPolicy,
          onTap: () => context.push('/privacy'),
        ),
        const SizedBox(height: 16),

        // Account section
        _sectionHeader(l.profileAccount),
        _menuItem(
          icon: Icons.logout,
          label: l.profileLogout,
          onTap: () async {
            final nav = GoRouter.of(context);
            await ref.read(authProvider.notifier).logout();
            if (mounted) nav.go('/login');
          },
        ),
        _menuItem(
          icon: Icons.delete_forever,
          label: l.profileDeleteAccount,
          color: AppColors.error,
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  IconData _themeIcon(String mode) {
    switch (mode) {
      case 'light': return Icons.light_mode;
      case 'system': return Icons.brightness_auto;
      default: return Icons.dark_mode;
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, String current, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.profileSelectTheme,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _themeOption(ctx, ref, l.profileThemeSystem, 'system', Icons.brightness_auto, current),
              _themeOption(ctx, ref, l.profileThemeLight, 'light', Icons.light_mode, current),
              _themeOption(ctx, ref, l.profileThemeDark, 'dark', Icons.dark_mode, current),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.profileSelectLanguage),
        children: [
          SimpleDialogOption(
            onPressed: () { ref.read(appProvider.notifier).setLocale('zh'); Navigator.pop(ctx); },
            child: Text(l.profileLangZh),
          ),
          SimpleDialogOption(
            onPressed: () { ref.read(appProvider.notifier).setLocale('en'); Navigator.pop(ctx); },
            child: Text(l.profileLangEn),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, WidgetRef ref, String label, String mode, IconData icon, String current) {
    final selected = current == mode;
    return InkWell(
      onTap: () {
        ref.read(appProvider.notifier).setThemeMode(mode);
        Navigator.pop(ctx);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.accentPrimary : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: AppColors.textPrimary))),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: AppColors.accentPrimary),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5)),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    String? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: c))),
            if (trailing != null)
              Text(trailing, style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
