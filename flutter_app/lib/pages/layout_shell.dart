import 'dart:async';
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
    final auth = ref.read(authProvider);
    if (!auth.isPlatformAdmin) return;
    try {
      final data = await ApiService.instance.listTenants();
      if (mounted) setState(() => _tenants = data.cast<Map<String, dynamic>>());
    } catch (_) {}
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgPrimary,
      drawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        width: 260,
        child: SafeArea(
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text('🚢', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Soloship', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                    IconButton(
                      onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                      icon: const Icon(Icons.close, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tenant switcher (platform admin only)
              if (auth.isPlatformAdmin) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: appState.currentTenantId.isEmpty ? null : appState.currentTenantId,
                        items: _tenants.map((t) => DropdownMenuItem(
                          value: t['id'] as String,
                          child: Text(t['name'] as String, style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            ref.read(appProvider.notifier).setTenant(v);
                            _loadAgents();
                          }
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        dropdownColor: AppColors.bgElevated,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                      if (_showNewCompany) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newCompanyCtl,
                                style: const TextStyle(fontSize: 11),
                                decoration: const InputDecoration(
                                  hintText: 'Company Name',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _createCompany(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(onTap: _createCompany, child: const Icon(Icons.check, size: 16, color: AppColors.accentPrimary)),
                            InkWell(onTap: () => setState(() => _showNewCompany = false),
                                child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary)),
                          ],
                        ),
                      ] else
                        TextButton.icon(
                          onPressed: () => setState(() => _showNewCompany = true),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('New Company', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            foregroundColor: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              // Nav items
              const SizedBox(height: 4),
              _navItem(Icons.storefront, 'Plaza', '/plaza', currentLocation),
              _navItem(Icons.dashboard, 'Dashboard', '/dashboard', currentLocation),
              const SizedBox(height: 8),
              // Agent list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('My Digital Employees',
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
              _navItem(Icons.add, 'New Agent', '/agents/new', currentLocation),
              if (auth.isAdmin)
                _navItem(Icons.settings, 'Enterprise', '/enterprise', currentLocation),
              if (auth.isPlatformAdmin)
                _navItem(Icons.confirmation_number, 'Invitations', '/invitations', currentLocation),
              const Divider(height: 1),
              // Footer
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => ref.read(appProvider.notifier).toggleTheme(),
                          icon: Icon(appState.themeMode == 'dark' ? Icons.light_mode : Icons.dark_mode, size: 16),
                          iconSize: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                    if (auth.user != null)
                      Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.bgTertiary,
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: const Icon(Icons.person, size: 16, color: AppColors.textTertiary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(auth.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                                Text(_roleLabel(auth.role), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final nav = GoRouter.of(context);
                              await ref.read(authProvider.notifier).logout();
                              if (mounted) nav.go('/login');
                            },
                            icon: const Icon(Icons.logout, size: 14),
                            iconSize: 14,
                            color: AppColors.textTertiary,
                            tooltip: 'Logout',
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
          // Full-screen content
          widget.child,
          // Menu button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: AppColors.bgSecondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.menu, size: 20, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
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
    if (_newCompanyCtl.text.isEmpty) return;
    try {
      final slug = _newCompanyCtl.text.toLowerCase().replaceAll(RegExp(r'[\s]+'), '-').replaceAll(RegExp(r'[^a-z0-9_-]'), '');
      await ApiService.instance.createTenant({'name': _newCompanyCtl.text, 'slug': slug, 'im_provider': 'web_only'});
      _newCompanyCtl.clear();
      setState(() => _showNewCompany = false);
      _loadTenants();
    } catch (_) {}
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'platform_admin': return 'Platform Admin';
      case 'org_admin': return 'Org Admin';
      case 'agent_admin': return 'Agent Admin';
      default: return 'Member';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _newCompanyCtl.dispose();
    super.dispose();
  }
}
