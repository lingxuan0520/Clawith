import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  List<Map<String, dynamic>> _tenants = [];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final data = await ApiService.instance.listTenants();
      if (mounted) setState(() => _tenants = data.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  String get _currentTenantName {
    final tenantId = ref.read(appProvider).currentTenantId;
    if (tenantId.isEmpty || _tenants.isEmpty) return '我的公司';
    final match = _tenants.where((t) => t['id'] == tenantId);
    return match.isNotEmpty ? (match.first['name'] as String? ?? '我的公司') : '我的公司';
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('删除账号', style: TextStyle(color: AppColors.error)),
        content: const Text(
          '此操作不可撤回。你的所有数据（Agent、聊天记录、任务等）将被永久删除。\n\n确定要删除账号吗？',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除', style: TextStyle(color: AppColors.error)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'platform_admin': return '平台管理员';
      case 'org_admin': return '企业管理员';
      case 'agent_admin': return 'Agent 管理员';
      default: return '成员';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final appState = ref.watch(appProvider);
    final avatarUrl = (auth.user?['avatar_url'] as String?)?.isNotEmpty == true
        ? auth.user!['avatar_url'] as String
        : fb.FirebaseAuth.instance.currentUser?.photoURL;

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
                    Text(_roleLabel(auth.role),
                        style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Company section
        _sectionHeader('公司'),
        _menuItem(
          icon: Icons.business,
          label: _currentTenantName,
          trailing: _tenants.length > 1 ? '切换' : null,
          onTap: () {
            if (_tenants.length > 1) {
              _showTenantSwitcher();
            }
          },
        ),
        _menuItem(
          icon: Icons.settings,
          label: '公司设置',
          onTap: () => context.push('/enterprise'),
        ),
        _menuItem(
          icon: Icons.add_business,
          label: '新建公司',
          onTap: () => _showCreateCompany(),
        ),
        const SizedBox(height: 16),

        // Settings section
        _sectionHeader('设置'),
        _menuItem(
          icon: appState.themeMode == 'dark' ? Icons.light_mode : Icons.dark_mode,
          label: appState.themeMode == 'dark' ? '切换到浅色模式' : '切换到深色模式',
          onTap: () => ref.read(appProvider.notifier).toggleTheme(),
        ),
        const SizedBox(height: 16),

        // About section
        _sectionHeader('关于'),
        _menuItem(
          icon: Icons.privacy_tip_outlined,
          label: '隐私政策',
          onTap: () => context.push('/privacy'),
        ),
        const SizedBox(height: 16),

        // Account section
        _sectionHeader('账号'),
        _menuItem(
          icon: Icons.logout,
          label: '退出登录',
          onTap: () async {
            final nav = GoRouter.of(context);
            await ref.read(authProvider.notifier).logout();
            if (mounted) nav.go('/login');
          },
        ),
        _menuItem(
          icon: Icons.delete_forever,
          label: '删除账号',
          color: AppColors.error,
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5)),
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
              Text(trailing, style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showTenantSwitcher() {
    final currentId = ref.read(appProvider).currentTenantId;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('切换公司', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ..._tenants.map((t) {
              final id = t['id'] as String;
              final name = t['name'] as String;
              final isSelected = id == currentId;
              return ListTile(
                title: Text(name, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                )),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.accentPrimary, size: 18) : null,
                onTap: () {
                  ref.read(appProvider.notifier).setTenant(id);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCreateCompany() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('新建公司'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '公司名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (ctl.text.trim().isEmpty) return;
              final name = ctl.text.trim();
              var slug = name.toLowerCase().replaceAll(RegExp(r'[\s]+'), '-').replaceAll(RegExp(r'[^a-z0-9_-]'), '');
              if (slug.length < 2) slug = 'co-${DateTime.now().millisecondsSinceEpoch}';
              try {
                final result = await ApiService.instance.createTenant({'name': name, 'slug': slug, 'im_provider': 'web_only'});
                final newId = result['id'] as String;
                ref.read(appProvider.notifier).setTenant(newId);
                await _loadTenants();
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (_) {}
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
