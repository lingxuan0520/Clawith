import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/auth_store.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';

class LayoutShell extends ConsumerStatefulWidget {
  final Widget child;
  const LayoutShell({super.key, required this.child});
  @override
  ConsumerState<LayoutShell> createState() => _LayoutShellState();
}

class _LayoutShellState extends ConsumerState<LayoutShell> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _tenants = [];
  bool _showNewCompany = false;
  final _newCompanyCtl = TextEditingController();
  Timer? _refreshTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _tenantKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _loadTenants();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAgents());
  }

  Future<void> _loadAgents() async {
    try {
      final tenantId = ref.read(appProvider).currentTenantId;
      final data = await ApiService.instance.listAgents(tenantId: tenantId.isEmpty ? null : tenantId);
      if (mounted) setState(() => _agents = data.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _loadTenants() async {
    try {
      final data = await ApiService.instance.listTenants();
      if (mounted) {
        setState(() => _tenants = data.cast<Map<String, dynamic>>());
        final appState = ref.read(appProvider);
        final auth = ref.read(authProvider);
        if (appState.currentTenantId.isEmpty && data.isNotEmpty) {
          final fallback = auth.tenantId ?? (data.first['id'] as String);
          ref.read(appProvider.notifier).setTenant(fallback);
          _loadAgents();
        }
      }
    } catch (_) {}
  }

  String get _currentTenantName {
    final tenantId = ref.read(appProvider).currentTenantId;
    if (tenantId.isEmpty || _tenants.isEmpty) return '';
    final match = _tenants.where((t) => t['id'] == tenantId);
    return match.isNotEmpty ? (match.first['name'] as String? ?? '') : '';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running': return AppColors.statusRunning;
      case 'stopped': return AppColors.statusStopped;
      case 'creating': return AppColors.warning;
      case 'error': return AppColors.statusError;
      default: return AppColors.statusIdle;
    }
  }

  void _navigate(String path) {
    _scaffoldKey.currentState?.closeDrawer();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final appState = ref.watch(appProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final avatarUrl = (auth.user?['avatar_url'] as String?)?.isNotEmpty == true
        ? auth.user!['avatar_url'] as String
        : fb.FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgPrimary,
      drawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        width: 260,
        child: SafeArea(
          child: Column(
            children: [
              // Top: Company name + switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company header with tap-to-switch
                    Row(
                      children: [
                        const Icon(Icons.business, size: 18, color: AppColors.accentPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tenants.length > 1
                              ? GestureDetector(
                                  key: _tenantKey,
                                  onTap: () {
                                    final box = _tenantKey.currentContext?.findRenderObject() as RenderBox?;
                                    if (box == null) return;
                                    final offset = box.localToGlobal(Offset.zero);
                                    final width = box.size.width;
                                    showMenu<String>(
                                      context: context,
                                      color: AppColors.bgElevated,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 8,
                                      constraints: BoxConstraints(minWidth: width, maxWidth: width),
                                      position: RelativeRect.fromLTRB(
                                        offset.dx,
                                        offset.dy + box.size.height + 4,
                                        offset.dx + width,
                                        0,
                                      ),
                                      items: _tenants.map((t) {
                                        final id = t['id'] as String;
                                        final name = t['name'] as String;
                                        final isSelected = id == ref.read(appProvider).currentTenantId;
                                        return PopupMenuItem<String>(
                                          value: id,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(name,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                    color: isSelected ? AppColors.accentPrimary : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(Icons.check, size: 14, color: AppColors.accentPrimary),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ).then((v) {
                                      if (v != null) {
                                        ref.read(appProvider.notifier).setTenant(v);
                                        _loadAgents();
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _currentTenantName.isNotEmpty ? _currentTenantName : '我的公司',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.unfold_more, size: 16, color: AppColors.textTertiary),
                                    ],
                                  ),
                                )
                              : Text(
                                  _currentTenantName.isNotEmpty ? _currentTenantName : '我的公司',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                    // New company
                    if (_showNewCompany) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCompanyCtl,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: '公司名称',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _createCompany(),
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(onTap: _createCompany, child: const Icon(Icons.check, size: 16, color: AppColors.accentPrimary)),
                          const SizedBox(width: 4),
                          InkWell(onTap: () => setState(() => _showNewCompany = false),
                              child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary)),
                        ],
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showNewCompany = true),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('新建公司', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            foregroundColor: AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Nav items
              const SizedBox(height: 4),
              _navItem(Icons.storefront, '广场', '/plaza', currentLocation),
              _navItem(Icons.dashboard, '仪表盘', '/dashboard', currentLocation),
              const SizedBox(height: 8),
              // Agent list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('我的数字员工',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary,
                        letterSpacing: 0.5)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _agents.length,
                  itemBuilder: (context, i) {
                    final agent = _agents[i];
                    final id = agent['id'] as String;
                    final name = agent['name'] as String? ?? 'Agent';
                    final status = agent['status'] as String? ?? 'idle';
                    final isActive = currentLocation == '/agents/$id';
                    return InkWell(
                      onTap: () => _navigate('/agents/$id'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.bgHover : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor(status),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(name,
                                  style: TextStyle(fontSize: 13, color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom section
              const Divider(height: 1),
              _navItem(Icons.add, '新建 Agent', '/agents/new', currentLocation),
              if (auth.isAdmin)
                _navItem(Icons.settings, '企业设置', '/enterprise', currentLocation),
              if (auth.isPlatformAdmin)
                _navItem(Icons.confirmation_number, '邀请码', '/invitations', currentLocation),
              const Divider(height: 1),
              // Footer: user info + theme + language
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    // Theme & language row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Language button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Text('中文', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => ref.read(appProvider.notifier).toggleTheme(),
                          icon: Icon(appState.themeMode == 'dark' ? Icons.light_mode : Icons.dark_mode, size: 16),
                          iconSize: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // User info
                    if (auth.user != null)
                      Row(
                        children: [
                          // Avatar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? Image.network(avatarUrl, width: 32, height: 32, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _defaultAvatar())
                                : _defaultAvatar(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.displayName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                Text(_roleLabel(auth.role),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final nav = GoRouter.of(context);
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) nav.go('/login');
                            },
                            icon: const Icon(Icons.logout, size: 16),
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppColors.textTertiary,
                            tooltip: '退出登录',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          widget.child,
          // Menu button + company name (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: AppColors.bgSecondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu, size: 20, color: AppColors.textPrimary),
                      if (_currentTenantName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(_currentTenantName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.bgTertiary,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Icon(Icons.person, size: 18, color: AppColors.textTertiary),
    );
  }

  Widget _navItem(IconData icon, String label, String path, String current) {
    final isActive = current == path || current.startsWith('$path/');
    return InkWell(
      onTap: () => _navigate(path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.bgHover : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.accentPrimary : AppColors.textTertiary),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: isActive ? AppColors.textPrimary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _createCompany() async {
    if (_newCompanyCtl.text.trim().isEmpty) return;
    try {
      final name = _newCompanyCtl.text.trim();
      // Generate slug: strip non-ascii to base, fallback to timestamp if empty
      var slug = name.toLowerCase().replaceAll(RegExp(r'[\s]+'), '-').replaceAll(RegExp(r'[^a-z0-9_-]'), '');
      if (slug.length < 2) {
        slug = 'co-${DateTime.now().millisecondsSinceEpoch}';
      }
      final result = await ApiService.instance.createTenant({'name': name, 'slug': slug, 'im_provider': 'web_only'});
      _newCompanyCtl.clear();
      setState(() => _showNewCompany = false);
      // Auto-switch to the newly created company
      final newId = result['id'] as String;
      ref.read(appProvider.notifier).setTenant(newId);
      await _loadTenants();
      _loadAgents();
    } catch (_) {}
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
  void dispose() {
    _refreshTimer?.cancel();
    _newCompanyCtl.dispose();
    super.dispose();
  }
}
