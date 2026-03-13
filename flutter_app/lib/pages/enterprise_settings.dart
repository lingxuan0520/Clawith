import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../stores/auth_store.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_client.dart';
import 'package:dio/dio.dart';

// ─── Enterprise Settings Page ─────────────────────────────────
class EnterpriseSettingsPage extends ConsumerStatefulWidget {
  const EnterpriseSettingsPage({super.key});

  @override
  ConsumerState<EnterpriseSettingsPage> createState() =>
      _EnterpriseSettingsPageState();
}

class _EnterpriseSettingsPageState
    extends ConsumerState<EnterpriseSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabLabels = [
    '公司信息',
    '模型池',
    '工具',
    '技能',
    '知识库',
    // '配额管理',  // 2B feature — hidden for 2C
    // '组织架构',  // 2B feature — hidden for 2C
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: const Text(
          '我的公司',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentPrimary,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CompanyInfoTab(),
          _LlmModelsTab(),
          _ToolsTab(),
          _SkillsTab(),
          _KnowledgeBaseTab(),
          // _QuotasUsersTab(),  // 2B feature — hidden for 2C
          // _OrgTab(),          // 2B feature — hidden for 2C
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Helper: Dio instance shortcut
// ═══════════════════════════════════════════════════════════════
Dio get _dio => ApiClient.instance.dio;

// ═══════════════════════════════════════════════════════════════
//  SECTION CARD – reusable card wrapper
// ═══════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  1. COMPANY INFO TAB
// ═══════════════════════════════════════════════════════════════
class _CompanyInfoTab extends ConsumerStatefulWidget {
  const _CompanyInfoTab();
  @override
  ConsumerState<_CompanyInfoTab> createState() => _CompanyInfoTabState();
}

class _CompanyInfoTabState extends ConsumerState<_CompanyInfoTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Company name
  final _nameCtl = TextEditingController();
  bool _nameSaving = false;
  bool _nameSaved = false;

  // Company intro
  final _introCtl = TextEditingController();
  bool _introSaving = false;
  bool _introSaved = false;

  // Notification bar
  bool _notifEnabled = false;
  final _notifTextCtl = TextEditingController();
  bool _notifSaving = false;
  bool _notifSaved = false;

  // Platform settings
  final _publicUrlCtl = TextEditingController();
  final _maxRoundsCtl = TextEditingController(text: '5');
  bool _platSaving = false;
  bool _platSaved = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Load company name from tenant
    try {
      final auth = ref.read(authProvider);
      final tenantId = auth.tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        final d = await _dio.get('/tenants/$tenantId');
        final data = d.data as Map<String, dynamic>;
        if (data['name'] != null) {
          _nameCtl.text = data['name'] as String;
        }
      }
    } catch (_) {}

    // Load company intro
    try {
      final d = await _dio.get('/enterprise/system-settings/company_intro');
      final data = d.data as Map<String, dynamic>;
      if (data['value'] is Map && data['value']['content'] != null) {
        _introCtl.text = data['value']['content'] as String;
      }
    } catch (_) {}

    // Load notification bar
    try {
      final d =
          await _dio.get('/enterprise/system-settings/notification_bar');
      final data = d.data as Map<String, dynamic>;
      if (data['value'] is Map) {
        _notifEnabled = data['value']['enabled'] == true;
        _notifTextCtl.text = (data['value']['text'] ?? '') as String;
      }
    } catch (_) {}

    // Load platform settings
    try {
      final d = await _dio.get('/enterprise/system-settings/platform');
      final data = d.data as Map<String, dynamic>;
      if (data['value'] is Map && data['value']['public_base_url'] != null) {
        _publicUrlCtl.text = data['value']['public_base_url'] as String;
      }
    } catch (_) {}
    try {
      final d =
          await _dio.get('/enterprise/system-settings/agent_conversation');
      final data = d.data as Map<String, dynamic>;
      if (data['value'] is Map && data['value']['max_rounds'] != null) {
        _maxRoundsCtl.text = data['value']['max_rounds'].toString();
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _saveCompanyName() async {
    final auth = ref.read(authProvider);
    final tenantId = auth.tenantId;
    if (tenantId == null || _nameCtl.text.trim().isEmpty) return;
    setState(() => _nameSaving = true);
    try {
      await _dio.put('/tenants/$tenantId',
          data: {'name': _nameCtl.text.trim()});
      setState(() => _nameSaved = true);
      Future.delayed(
          const Duration(seconds: 2), () => mounted ? setState(() => _nameSaved = false) : null);
    } catch (_) {
      _showError('Failed to save company name');
    }
    setState(() => _nameSaving = false);
  }

  Future<void> _saveCompanyIntro() async {
    setState(() => _introSaving = true);
    try {
      await _dio.put('/enterprise/system-settings/company_intro', data: {
        'value': {'content': _introCtl.text}
      });
      setState(() => _introSaved = true);
      Future.delayed(
          const Duration(seconds: 2), () => mounted ? setState(() => _introSaved = false) : null);
    } catch (_) {
      _showError('Failed to save company intro');
    }
    setState(() => _introSaving = false);
  }

  Future<void> _saveNotificationBar() async {
    setState(() => _notifSaving = true);
    try {
      await _dio.put('/enterprise/system-settings/notification_bar', data: {
        'value': {'enabled': _notifEnabled, 'text': _notifTextCtl.text}
      });
      setState(() => _notifSaved = true);
      Future.delayed(
          const Duration(seconds: 2), () => mounted ? setState(() => _notifSaved = false) : null);
    } catch (_) {
      _showError('Failed to save notification bar');
    }
    setState(() => _notifSaving = false);
  }

  Future<void> _savePlatformSettings() async {
    setState(() => _platSaving = true);
    try {
      await _dio.put('/enterprise/system-settings/platform', data: {
        'value': {'public_base_url': _publicUrlCtl.text}
      });
      await _dio.put('/enterprise/system-settings/agent_conversation', data: {
        'value': {'max_rounds': int.tryParse(_maxRoundsCtl.text) ?? 5}
      });
      setState(() => _platSaved = true);
      Future.delayed(
          const Duration(seconds: 2), () => mounted ? setState(() => _platSaved = false) : null);
    } catch (_) {
      _showError('Failed to save platform settings');
    }
    setState(() => _platSaving = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Notification Bar Config ──
        _buildSectionHeader('Notification Bar',
            subtitle:
                'Display a notification bar at the top of the page, visible to all users.'),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _notifEnabled,
                      onChanged: (v) =>
                          setState(() => _notifEnabled = v ?? false),
                      activeColor: AppColors.accentPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Enable notification bar',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notifTextCtl,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notification text',
                  hintText: 'e.g. v2.1 released with new features!',
                ),
              ),
              if (_notifEnabled && _notifTextCtl.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Preview:',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _notifTextCtl.text,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildSaveRow(
                saving: _notifSaving,
                saved: _notifSaved,
                onSave: _saveNotificationBar,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Company Name ──
        _buildSectionHeader('Company Name'),
        const SizedBox(height: 8),
        _SectionCard(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtl,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Enter company name',
                  ),
                  onSubmitted: (_) => _saveCompanyName(),
                ),
              ),
              const SizedBox(width: 12),
              _buildSaveButton(
                saving: _nameSaving,
                saved: _nameSaved,
                onSave: _saveCompanyName,
                enabled: _nameCtl.text.trim().isNotEmpty,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Company Intro ──
        _buildSectionHeader('Company Intro',
            subtitle:
                "Describe your company's mission, products, and culture. This information is included in every agent conversation as context."),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _introCtl,
                maxLines: 10,
                minLines: 6,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    height: 1.6),
                decoration: const InputDecoration(
                  hintText:
                      '# Company Name\n\n## About Us\nDescribe your company here...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSaveButton(
                    saving: _introSaving,
                    saved: _introSaved,
                    onSave: _saveCompanyIntro,
                  ),
                  const Spacer(),
                  const Text(
                    "This content appears in every agent's system prompt",
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Platform Configuration ──
        _buildSectionHeader('Platform Configuration'),
        const SizedBox(height: 8),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Public Base URL',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _publicUrlCtl,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'https://your-server.com',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Public Base URL for external access',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Max Conversation Rounds',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _maxRoundsCtl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: '5',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                            'Maximum back-and-forth rounds between agents',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSaveRow(
                saving: _platSaving,
                saved: _platSaved,
                onSave: _savePlatformSettings,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Theme Color Picker ──
        _SectionCard(
          child: _ThemeColorPicker(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _introCtl.dispose();
    _notifTextCtl.dispose();
    _publicUrlCtl.dispose();
    _maxRoundsCtl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
//  THEME COLOR PICKER
// ═══════════════════════════════════════════════════════════════
class _ThemeColorPicker extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends ConsumerState<_ThemeColorPicker> {
  final _hexCtl = TextEditingController();

  static const _presets = [
    {'name': 'Blue', 'hex': '#5A96FF'},
    {'name': 'Purple', 'hex': '#9C7CF4'},
    {'name': 'Green', 'hex': '#22C55E'},
    {'name': 'Teal', 'hex': '#14B8A6'},
    {'name': 'Orange', 'hex': '#F97316'},
    {'name': 'Pink', 'hex': '#EC4899'},
    {'name': 'Red', 'hex': '#EF4444'},
    {'name': 'Yellow', 'hex': '#EAB308'},
  ];

  void _apply(String hex) {
    ref.read(appProvider.notifier).setAccentColor(hex);
  }

  void _reset() {
    ref.read(appProvider.notifier).setAccentColor(null);
    _hexCtl.clear();
  }

  void _applyCustom() {
    final hex = _hexCtl.text.trim();
    final valid = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex);
    if (!valid) return;
    _apply(hex);
  }

  @override
  void dispose() {
    _hexCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = ref.watch(appProvider).accentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme Accent Color',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((p) {
            final hex = p['hex']!;
            final isSelected = currentColor == hex;
            final color = Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
            return GestureDetector(
              onTap: () => _apply(hex),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _hexCtl,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: '#hex',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  isDense: true,
                ),
                onSubmitted: (_) => _applyCustom(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _applyCustom,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Apply'),
            ),
            if (currentColor != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(int.parse(
                      'FF${currentColor.replaceFirst('#', '')}', radix: 16)),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderDefault),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  7. ORG STRUCTURE TAB
// ═══════════════════════════════════════════════════════════════
class _OrgTab extends ConsumerStatefulWidget {
  const _OrgTab();

  @override
  ConsumerState<_OrgTab> createState() => _OrgTabState();
}

class _OrgTabState extends ConsumerState<_OrgTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _appIdCtl = TextEditingController();
  final _appSecretCtl = TextEditingController();
  final _memberSearchCtl = TextEditingController();
  bool _syncing = false;
  Map<String, dynamic>? _syncResult;
  List<dynamic> _departments = [];
  List<dynamic> _members = [];
  String? _selectedDeptId;
  bool _loadingDepts = false;
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadDepartments();
    _memberSearchCtl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _loadMembers();
  }

  Future<void> _loadConfig() async {
    try {
      final data = await ApiService.instance.getSystemSetting('feishu_org_sync');
      if (!mounted) return;
      final appId = data?['value']?['app_id'] as String?;
      if (appId != null) setState(() => _appIdCtl.text = appId);
    } catch (_) {}
  }

  Future<void> _loadDepartments() async {
    if (!mounted) return;
    setState(() => _loadingDepts = true);
    try {
      final tenantId = ref.read(appProvider).currentTenantId;
      final data = await ApiService.instance.listOrgDepartments(
          tenantId: tenantId.isNotEmpty ? tenantId : null);
      if (!mounted) return;
      setState(() {
        _departments = data;
        _loadingDepts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() => _loadingMembers = true);
    try {
      final tenantId = ref.read(appProvider).currentTenantId;
      final data = await ApiService.instance.listOrgMembers(
        departmentId: _selectedDeptId,
        search: _memberSearchCtl.text.trim(),
        tenantId: tenantId.isNotEmpty ? tenantId : null,
      );
      if (!mounted) return;
      setState(() {
        _members = data;
        _loadingMembers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _triggerSync() async {
    if (_appIdCtl.text.trim().isEmpty) return;
    setState(() {
      _syncing = true;
      _syncResult = null;
    });
    try {
      if (_appSecretCtl.text.trim().isNotEmpty) {
        await ApiService.instance.setSystemSetting('feishu_org_sync', {
          'app_id': _appIdCtl.text.trim(),
          'app_secret': _appSecretCtl.text.trim(),
        });
      }
      final result = await ApiService.instance.syncOrg();
      if (!mounted) return;
      setState(() {
        _syncResult = result;
        _syncing = false;
      });
      _loadDepartments();
      _loadMembers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _syncResult = {'error': e.toString()};
        _syncing = false;
      });
    }
  }

  void _selectDept(String? id) {
    setState(() => _selectedDeptId = id);
    _loadMembers();
  }

  @override
  void dispose() {
    _appIdCtl.dispose();
    _appSecretCtl.dispose();
    _memberSearchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Feishu Sync Config ──
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Feishu 组织同步',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('通过飞书开放平台同步企业组织架构',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App ID',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _appIdCtl,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'cli_xxxxxxxx',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('App Secret',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _appSecretCtl,
                            obscureText: true,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: '留空保持不变',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: (_syncing || _appIdCtl.text.trim().isEmpty)
                          ? null
                          : _triggerSync,
                      child: _syncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('立即同步'),
                    ),
                    if (_syncResult != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _syncResult!.containsKey('error')
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _syncResult!.containsKey('error')
                                ? '同步失败: ${_syncResult!['error']}'
                                : '同步完成 · ${_syncResult!['departments'] ?? 0} 部门 · ${_syncResult!['members'] ?? 0} 成员',
                            style: TextStyle(
                              fontSize: 12,
                              color: _syncResult!.containsKey('error')
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Org Browser ──
          _SectionCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text('组织架构浏览',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                SizedBox(
                  height: 500,
                  child: Row(
                    children: [
                      // Dept tree
                      SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Text('部门',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textTertiary)),
                            ),
                            // All departments item
                            _deptItem(null, '全部'),
                            Expanded(
                              child: _loadingDepts
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : _departments.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text('暂无数据',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textTertiary)),
                                        )
                                      : ListView(
                                          children: _departments
                                              .map((d) => _deptItem(
                                                    d['id'] as String?,
                                                    d['name'] as String? ?? '-',
                                                  ))
                                              .toList(),
                                        ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(
                          width: 1, color: AppColors.borderSubtle),
                      // Members list
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: TextField(
                                controller: _memberSearchCtl,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: '搜索成员...',
                                  prefixIcon: Icon(Icons.search,
                                      size: 16,
                                      color: AppColors.textTertiary),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _loadingMembers
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : _members.isEmpty
                                      ? const Center(
                                          child: Text('暂无成员',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textTertiary)),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          itemCount: _members.length,
                                          itemBuilder: (_, i) {
                                            final m = _members[i]
                                                as Map<String, dynamic>;
                                            final name =
                                                m['name'] as String? ?? '-';
                                            final title =
                                                m['title'] as String?;
                                            final deptPath =
                                                m['department_path']
                                                    as String?;
                                            final email =
                                                m['email'] as String?;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 4),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        AppColors.borderSubtle),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          AppColors.bgTertiary,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                          : '?',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(name,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColors
                                                                    .textPrimary)),
                                                        Text(
                                                          [
                                                            if (title != null)
                                                              title,
                                                            if (deptPath !=
                                                                null)
                                                              deptPath,
                                                            if (email != null)
                                                              email,
                                                          ].join(' · '),
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AppColors
                                                                  .textTertiary),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deptItem(String? id, String name) {
    final isSelected = _selectedDeptId == id;
    return InkWell(
      onTap: () => _selectDept(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.bgHover : Colors.transparent,
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  2. LLM MODELS TAB
// ═══════════════════════════════════════════════════════════════
class _LlmModelsTab extends StatefulWidget {
  const _LlmModelsTab();
  @override
  State<_LlmModelsTab> createState() => _LlmModelsTabState();
}

class _LlmModelsTabState extends State<_LlmModelsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _models = [];
  bool _loading = true;

  // Add / edit form
  bool _showForm = false;
  String? _editingModelId;
  String _provider = 'anthropic';
  final _modelCtl = TextEditingController();
  final _labelCtl = TextEditingController();
  final _apiKeyCtl = TextEditingController();
  final _baseUrlCtl = TextEditingController();
  bool _supportsVision = false;

  static const _providers = [
    ('anthropic', 'Anthropic'),
    ('openai', 'OpenAI'),
    ('deepseek', 'DeepSeek'),
    ('minimax', 'MiniMax'),
    ('qwen', 'Qwen (DashScope)'),
    ('zhipu', 'Zhipu'),
    ('openrouter', 'OpenRouter'),
    ('custom', '自定义'),
  ];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listLlmModels();
      _models = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _openAddForm() {
    setState(() {
      _editingModelId = null;
      _provider = 'anthropic';
      _modelCtl.clear();
      _labelCtl.clear();
      _apiKeyCtl.clear();
      _baseUrlCtl.clear();
      _supportsVision = false;
      _showForm = true;
    });
  }

  void _openEditForm(Map<String, dynamic> m) {
    setState(() {
      _editingModelId = m['id'] as String;
      _provider = (m['provider'] ?? 'anthropic') as String;
      _modelCtl.text = (m['model'] ?? '') as String;
      _labelCtl.text = (m['label'] ?? '') as String;
      _apiKeyCtl.clear(); // don't prefill api key
      _baseUrlCtl.text = (m['base_url'] ?? '') as String;
      _supportsVision = m['supports_vision'] == true;
      _showForm = true;
    });
  }

  Future<void> _saveModel() async {
    final body = <String, dynamic>{
      'provider': _provider,
      'model': _modelCtl.text.trim(),
      'label': _labelCtl.text.trim(),
      'base_url': _baseUrlCtl.text.trim(),
      'supports_vision': _supportsVision,
    };
    if (_apiKeyCtl.text.trim().isNotEmpty) {
      body['api_key'] = _apiKeyCtl.text.trim();
    }

    try {
      if (_editingModelId != null) {
        await _dio.put('/enterprise/llm-models/$_editingModelId', data: body);
      } else {
        body['api_key'] = _apiKeyCtl.text.trim();
        await _dio.post('/enterprise/llm-models', data: body);
      }
      setState(() {
        _showForm = false;
        _editingModelId = null;
      });
      _loadModels();
    } catch (e) {
      _showError('保存模型失败');
    }
  }

  Future<void> _deleteModel(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('删除模型',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('确定要删除这个模型吗？',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('删除', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _dio.delete('/enterprise/llm-models/$id');
      _loadModels();
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data as Map<String, dynamic>?;
        final agents =
            (data?['detail']?['agents'] as List<dynamic>?)?.join(', ') ??
                'some agents';
        if (!mounted) return;
        final forceConfirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgElevated,
            title: const Text('模型使用中',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
                '此模型正在被以下 Agent 使用: $agents\n\n确定删除吗？',
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('强制删除',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
        if (forceConfirmed == true) {
          await _dio.delete('/enterprise/llm-models/$id',
              queryParameters: {'force': 'true'});
          _loadModels();
        }
      } else {
        _showError('删除模型失败');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Add button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _openAddForm,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加模型'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Add/Edit form
        if (_showForm) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingModelId != null ? '编辑模型' : '添加模型',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('供应商',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.borderDefault),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _provider,
                                isExpanded: true,
                                dropdownColor: AppColors.bgElevated,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                items: _providers
                                    .map((p) => DropdownMenuItem(
                                        value: p.$1,
                                        child: Text(p.$2)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _provider = v ?? _provider),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('模型名称',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _modelCtl,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'claude-sonnet-4-5',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('显示名称',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _labelCtl,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Claude Sonnet',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('自定义 Base URL',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _baseUrlCtl,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'https://api.custom.com/v1',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Key',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _apiKeyCtl,
                      obscureText: true,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _editingModelId != null
                            ? '留空保持不变'
                            : 'sk-...',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _supportsVision,
                        onChanged: (v) =>
                            setState(() => _supportsVision = v ?? false),
                        activeColor: AppColors.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: '支持视觉（多模态）',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                            TextSpan(
                                text:
                                    ' — 勾选后可分析图片',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _showForm = false;
                        _editingModelId = null;
                      }),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _modelCtl.text.isNotEmpty &&
                                  (_editingModelId != null ||
                                      _apiKeyCtl.text.isNotEmpty)
                              ? _saveModel
                              : null,
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Model list
        if (_models.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('暂无模型配置',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._models.map(_buildModelCard),
      ],
    );
  }

  Widget _buildModelCard(Map<String, dynamic> m) {
    final enabled = m['enabled'] == true;
    final vision = m['supports_vision'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (m['label'] ?? m['model'] ?? '') as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m['provider']}/${m['model']}${m['base_url'] != null && (m['base_url'] as String).isNotEmpty ? ' \u00b7 ${m['base_url']}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(enabled ? 'Enabled' : 'Disabled',
                enabled ? AppColors.success : AppColors.warning),
            if (vision) ...[
              const SizedBox(width: 6),
              _buildBadge('Vision', const Color(0xFF6366F1)),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _openEditForm(m),
              tooltip: '编辑',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.error),
              onPressed: () => _deleteModel(m['id'] as String),
              tooltip: '删除',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _modelCtl.dispose();
    _labelCtl.dispose();
    _apiKeyCtl.dispose();
    _baseUrlCtl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
//  3. TOOLS TAB
// ═══════════════════════════════════════════════════════════════
class _ToolsTab extends StatefulWidget {
  const _ToolsTab();
  @override
  State<_ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<_ToolsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _tools = [];
  bool _loading = true;

  // MCP add form
  bool _showAddMCP = false;
  final _mcpUrlCtl = TextEditingController();
  final _mcpNameCtl = TextEditingController();
  bool _mcpTesting = false;
  Map<String, dynamic>? _mcpTestResult;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listTools();
      _tools = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleTool(String toolId, bool enabled) async {
    try {
      await _dio
          .put('/tools/$toolId', data: {'enabled': enabled});
      _loadTools();
    } catch (_) {}
  }

  Future<void> _deleteTool(String toolId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Delete Tool',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "$displayName"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _dio.delete('/tools/$toolId');
      _loadTools();
    } catch (_) {
      _showError('Failed to delete tool');
    }
  }

  Future<void> _testMcpConnection() async {
    setState(() {
      _mcpTesting = true;
      _mcpTestResult = null;
    });
    try {
      final r = await _dio.post('/tools/test-mcp',
          data: {'server_url': _mcpUrlCtl.text.trim()});
      setState(() => _mcpTestResult = r.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _mcpTestResult = {'ok': false, 'error': e.toString()});
    }
    setState(() => _mcpTesting = false);
  }

  Future<void> _importMcpTool(Map<String, dynamic> tool) async {
    try {
      await _dio.post('/tools', data: {
        'name': 'mcp_${tool['name']}',
        'display_name': tool['name'],
        'description': tool['description'] ?? '',
        'type': 'mcp',
        'category': 'custom',
        'icon': '\u00b7',
        'mcp_server_url': _mcpUrlCtl.text.trim(),
        'mcp_server_name': _mcpNameCtl.text.trim().isNotEmpty
            ? _mcpNameCtl.text.trim()
            : _mcpUrlCtl.text.trim(),
        'mcp_tool_name': tool['name'],
        'parameters_schema': tool['inputSchema'] ?? {},
        'is_default': false,
      });
      _loadTools();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${tool['name']}')),
        );
      }
    } catch (_) {
      _showError('Failed to import tool');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Global Tools',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddMCP = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('MCP Server'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // MCP add form
        if (_showAddMCP) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add MCP Server',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text('Server Name',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _mcpNameCtl,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(hintText: 'My MCP Server'),
                ),
                const SizedBox(height: 10),
                const Text('MCP Server URL',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _mcpUrlCtl,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'http://localhost:3000/mcp'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _mcpTesting || _mcpUrlCtl.text.trim().isEmpty
                          ? null
                          : _testMcpConnection,
                      child: Text(
                          _mcpTesting ? 'Testing...' : 'Test Connection'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _showAddMCP = false;
                        _mcpTestResult = null;
                      }),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                // Test result
                if (_mcpTestResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mcpTestResult!['ok'] == true
                          ? const Color(0x1A22C55E)
                          : const Color(0x1AEF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _mcpTestResult!['ok'] == true
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: _mcpTestResult!['ok'] == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected! Found ${(_mcpTestResult!['tools'] as List?)?.length ?? 0} tools',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              ...(_mcpTestResult!['tools'] as List? ?? [])
                                  .map<Widget>((tool) {
                                final t = tool as Map<String, dynamic>;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(t['name'] as String? ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textPrimary)),
                                            if (t['description'] != null)
                                              Text(
                                                (t['description'] as String)
                                                    .substring(
                                                        0,
                                                        (t['description']
                                                                        as String)
                                                                    .length >
                                                                80
                                                            ? 80
                                                            : (t['description']
                                                                    as String)
                                                                .length),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .textTertiary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _importMcpTool(t),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          textStyle:
                                              const TextStyle(fontSize: 11),
                                        ),
                                        child: const Text('Import'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          )
                        : Text(
                            'Connection failed: ${_mcpTestResult!['error'] ?? 'Unknown error'}',
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tool list
        if (_tools.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No tools available',
                  style:
                      TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._tools.map(_buildToolCard),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final enabled = tool['enabled'] == true;
    final isMcp = tool['type'] == 'mcp';
    final isBuiltin = tool['type'] == 'builtin';
    final displayName = (tool['display_name'] ?? tool['name'] ?? '') as String;
    final description = (tool['description'] ?? '') as String;
    final mcpServerName = (tool['mcp_server_name'] ?? '') as String;
    final isDefault = tool['is_default'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            SizedBox(
              width: 28,
              child: Text(
                (tool['icon'] ?? '\u00b7') as String,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildBadge(
                        isMcp ? 'MCP' : 'Built-in',
                        isMcp
                            ? AppColors.accentPrimary
                            : AppColors.bgTertiary,
                        textColor: isMcp
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 4),
                        _buildBadge('Default', AppColors.success,
                            textColor: Colors.white),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description.length > 60
                        ? '${description.substring(0, 60)}...'
                        : description +
                            (mcpServerName.isNotEmpty
                                ? ' \u00b7 $mcpServerName'
                                : ''),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Actions
            if (!isBuiltin)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.error),
                onPressed: () =>
                    _deleteTool(tool['id'] as String, displayName),
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 4),
            // Enable/disable switch
            SizedBox(
              width: 44,
              height: 24,
              child: Switch(
                value: enabled,
                onChanged: (v) =>
                    _toggleTool(tool['id'] as String, v),
                activeTrackColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mcpUrlCtl.dispose();
    _mcpNameCtl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
//  4. SKILLS TAB
// ═══════════════════════════════════════════════════════════════
class _SkillsTab extends StatefulWidget {
  const _SkillsTab();
  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;
  String _currentPath = '';
  List<Map<String, dynamic>> _files = [];
  bool _filesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    _loadFiles('');
  }

  Future<void> _loadSkills() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listSkills();
      _skills = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _filesLoading = true;
      _currentPath = path;
    });
    try {
      final r = await _dio.get('/skills/browse/files',
          queryParameters: {'path': path});
      final data = r.data as List<dynamic>;
      _files = data.cast<Map<String, dynamic>>();
    } catch (_) {
      _files = [];
    }
    if (mounted) setState(() => _filesLoading = false);
  }

  void _navigateToFolder(String name) {
    final newPath =
        _currentPath.isEmpty ? name : '$_currentPath/$name';
    _loadFiles(newPath);
  }

  void _navigateUp() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    _loadFiles(parts.join('/'));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Skill Registry',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          'Manage global skills. Each skill is a folder with a SKILL.md file. '
          "Skills selected during agent creation are copied to the agent's workspace.",
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),

        // Skills list
        if (_loading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_skills.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No skills defined',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._skills.map(_buildSkillCard),

        const SizedBox(height: 24),
        const Divider(color: AppColors.borderSubtle),
        const SizedBox(height: 16),

        // Skill files browser
        const Text('Skill Files',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),

        // Breadcrumb
        Row(
          children: [
            InkWell(
              onTap: () => _loadFiles(''),
              child: const Text('root',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentText,
                      decoration: TextDecoration.underline)),
            ),
            if (_currentPath.isNotEmpty) ...[
              ..._currentPath.split('/').asMap().entries.map((entry) {
                final idx = entry.key;
                final part = entry.value;
                final pathUpTo = _currentPath
                    .split('/')
                    .sublist(0, idx + 1)
                    .join('/');
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(' / ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                    InkWell(
                      onTap: () => _loadFiles(pathUpTo),
                      child: Text(part,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accentText,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                );
              }),
            ],
            const Spacer(),
            if (_currentPath.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_upward,
                    size: 16, color: AppColors.textSecondary),
                onPressed: _navigateUp,
                tooltip: 'Go up',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _loadFiles(_currentPath),
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_filesLoading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_files.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Empty directory',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _files.asMap().entries.map((entry) {
                final f = entry.value;
                final isLast = entry.key == _files.length - 1;
                final isDir = f['type'] == 'directory';
                final name = (f['name'] ?? '') as String;
                return InkWell(
                  onTap: isDir ? () => _navigateToFolder(name) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                  color: AppColors.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDir
                              ? Icons.folder_outlined
                              : Icons.description_outlined,
                          size: 18,
                          color: isDir
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDir
                                      ? AppColors.accentText
                                      : AppColors.textPrimary)),
                        ),
                        if (f['size'] != null)
                          Text(_formatBytes(f['size'] as int),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final name = (skill['name'] ?? '') as String;
    final description = (skill['description'] ?? '') as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_outlined,
                  size: 20, color: AppColors.accentPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  if (description.isNotEmpty)
                    Text(description,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  5. QUOTAS & USERS TAB
// ═══════════════════════════════════════════════════════════════
class _QuotasUsersTab extends ConsumerStatefulWidget {
  const _QuotasUsersTab();
  @override
  ConsumerState<_QuotasUsersTab> createState() => _QuotasUsersTabState();
}

class _QuotasUsersTabState extends ConsumerState<_QuotasUsersTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Quota form
  int _defaultMessageLimit = 50;
  String _defaultMessagePeriod = 'permanent';
  int _defaultMaxAgents = 2;
  int _defaultAgentTtlHours = 48;
  int _defaultMaxLlmCallsPerDay = 100;
  int _minHeartbeatIntervalMinutes = 120;
  bool _quotaSaving = false;
  bool _quotaSaved = false;

  // Users
  List<Map<String, dynamic>> _users = [];
  bool _usersLoading = true;
  String? _editingUserId;
  final _userMsgLimitCtl = TextEditingController();
  final _userMaxAgentsCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuotas();
    _loadUsers();
  }

  Future<void> _loadQuotas() async {
    try {
      final r = await _dio.get('/enterprise/tenant-quotas');
      final data = r.data as Map<String, dynamic>;
      setState(() {
        _defaultMessageLimit =
            (data['default_message_limit'] ?? 50) as int;
        _defaultMessagePeriod =
            (data['default_message_period'] ?? 'permanent') as String;
        _defaultMaxAgents = (data['default_max_agents'] ?? 2) as int;
        _defaultAgentTtlHours =
            (data['default_agent_ttl_hours'] ?? 48) as int;
        _defaultMaxLlmCallsPerDay =
            (data['default_max_llm_calls_per_day'] ?? 100) as int;
        _minHeartbeatIntervalMinutes =
            (data['min_heartbeat_interval_minutes'] ?? 120) as int;
      });
    } catch (_) {}
  }

  Future<void> _saveQuotas() async {
    setState(() => _quotaSaving = true);
    try {
      await _dio.patch('/enterprise/tenant-quotas', data: {
        'default_message_limit': _defaultMessageLimit,
        'default_message_period': _defaultMessagePeriod,
        'default_max_agents': _defaultMaxAgents,
        'default_agent_ttl_hours': _defaultAgentTtlHours,
        'default_max_llm_calls_per_day': _defaultMaxLlmCallsPerDay,
        'min_heartbeat_interval_minutes': _minHeartbeatIntervalMinutes,
      });
      setState(() => _quotaSaved = true);
      Future.delayed(const Duration(seconds: 2),
          () => mounted ? setState(() => _quotaSaved = false) : null);
    } catch (_) {
      _showError('Failed to save quotas');
    }
    setState(() => _quotaSaving = false);
  }

  Future<void> _loadUsers() async {
    setState(() => _usersLoading = true);
    try {
      final r = await _dio.get('/enterprise/users');
      final data = r.data as List<dynamic>;
      _users = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _usersLoading = false);
  }

  void _startEditUser(Map<String, dynamic> user) {
    setState(() {
      _editingUserId = user['id'] as String;
      _userMsgLimitCtl.text =
          (user['message_limit'] ?? '').toString();
      _userMaxAgentsCtl.text =
          (user['max_agents'] ?? '').toString();
    });
  }

  Future<void> _saveUserQuota(String userId) async {
    try {
      await _dio.patch('/enterprise/users/$userId/quota', data: {
        'message_limit': int.tryParse(_userMsgLimitCtl.text),
        'max_agents': int.tryParse(_userMaxAgentsCtl.text),
      });
      setState(() => _editingUserId = null);
      _loadUsers();
    } catch (_) {
      _showError('Failed to save user quota');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Default Quotas ──
        const Text('Default User Quotas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          'These defaults apply to newly registered users. Existing users are not affected.',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conversation limits
              const Text('Conversation Limits',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuotaField(
                      'Message Limit',
                      'Max messages per period',
                      _defaultMessageLimit.toString(),
                      (v) => _defaultMessageLimit =
                          int.tryParse(v) ?? _defaultMessageLimit,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Message Period',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.borderDefault),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _defaultMessagePeriod,
                              isExpanded: true,
                              dropdownColor: AppColors.bgElevated,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                              items: const [
                                DropdownMenuItem(
                                    value: 'permanent',
                                    child: Text('Permanent')),
                                DropdownMenuItem(
                                    value: 'daily',
                                    child: Text('Daily')),
                                DropdownMenuItem(
                                    value: 'weekly',
                                    child: Text('Weekly')),
                                DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('Monthly')),
                              ],
                              onChanged: (v) => setState(
                                  () => _defaultMessagePeriod = v ?? 'permanent'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text('Agent Limits',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuotaField(
                      'Max Agents',
                      'Agents a user can create',
                      _defaultMaxAgents.toString(),
                      (v) => _defaultMaxAgents =
                          int.tryParse(v) ?? _defaultMaxAgents,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuotaField(
                      'Agent TTL (hours)',
                      'Agent auto-expiry time',
                      _defaultAgentTtlHours.toString(),
                      (v) => _defaultAgentTtlHours =
                          int.tryParse(v) ?? _defaultAgentTtlHours,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuotaField(
                      'Daily LLM Calls / Agent',
                      'Max LLM calls per agent per day',
                      _defaultMaxLlmCallsPerDay.toString(),
                      (v) => _defaultMaxLlmCallsPerDay =
                          int.tryParse(v) ?? _defaultMaxLlmCallsPerDay,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text('System',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: _buildQuotaField(
                  'Min Heartbeat Interval (min)',
                  'Minimum heartbeat interval for all agents',
                  _minHeartbeatIntervalMinutes.toString(),
                  (v) => _minHeartbeatIntervalMinutes =
                      int.tryParse(v) ?? _minHeartbeatIntervalMinutes,
                ),
              ),

              const SizedBox(height: 16),
              _buildSaveRow(
                saving: _quotaSaving,
                saved: _quotaSaved,
                onSave: _saveQuotas,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Users List ──
        const Text('Users',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),

        if (_usersLoading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_users.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No users found',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: AppColors.borderDefault)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Text('User',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('Role',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('Msg Limit',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('Max Agents',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      SizedBox(width: 60),
                    ],
                  ),
                ),
                // User rows
                ..._users.asMap().entries.map((entry) {
                  final u = entry.value;
                  final isEditing = _editingUserId == u['id'];
                  final isLast = entry.key == _users.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                  color: AppColors.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  (u['display_name'] ?? u['username'] ?? '')
                                      as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: AppColors.textPrimary)),
                              Text((u['email'] ?? '') as String,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text((u['role'] ?? 'member') as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: isEditing
                              ? SizedBox(
                                  height: 32,
                                  child: TextField(
                                    controller: _userMsgLimitCtl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      isDense: true,
                                    ),
                                  ),
                                )
                              : Text(
                                  (u['message_limit'] ?? '-').toString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: isEditing
                              ? SizedBox(
                                  height: 32,
                                  child: TextField(
                                    controller: _userMaxAgentsCtl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      contentPadding:
                                          EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      isDense: true,
                                    ),
                                  ),
                                )
                              : Text(
                                  (u['max_agents'] ?? '-').toString(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                        ),
                        SizedBox(
                          width: 60,
                          child: isEditing
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _saveUserQuota(
                                          u['id'] as String),
                                      child: const Icon(Icons.check,
                                          size: 16,
                                          color: AppColors.success),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => setState(
                                          () => _editingUserId = null),
                                      child: const Icon(Icons.close,
                                          size: 16,
                                          color: AppColors.textTertiary),
                                    ),
                                  ],
                                )
                              : InkWell(
                                  onTap: () => _startEditUser(u),
                                  child: const Icon(Icons.edit_outlined,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuotaField(
      String label, String hint, String initialValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          style:
              const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: const InputDecoration(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(hint,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  @override
  void dispose() {
    _userMsgLimitCtl.dispose();
    _userMaxAgentsCtl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
//  6. KNOWLEDGE BASE TAB
// ═══════════════════════════════════════════════════════════════
class _KnowledgeBaseTab extends StatefulWidget {
  const _KnowledgeBaseTab();
  @override
  State<_KnowledgeBaseTab> createState() => _KnowledgeBaseTabState();
}

class _KnowledgeBaseTabState extends State<_KnowledgeBaseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _currentPath = '';
  List<Map<String, dynamic>> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles('');
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _loading = true;
      _currentPath = path;
    });
    try {
      final data = await ApiService.instance.listKbFiles(path: path);
      _files = data.cast<Map<String, dynamic>>();
    } catch (_) {
      _files = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _navigateToFolder(String name) {
    final newPath =
        _currentPath.isEmpty ? name : '$_currentPath/$name';
    _loadFiles(newPath);
  }

  void _navigateUp() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    _loadFiles(parts.join('/'));
  }

  Future<void> _deleteFile(String name) async {
    final path =
        _currentPath.isEmpty ? name : '$_currentPath/$name';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Delete File',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "$name"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _dio.delete('/enterprise/knowledge-base/files',
          queryParameters: {'path': path});
      _loadFiles(_currentPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete file')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Enterprise Knowledge Base',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          'Shared files accessible to all agents via enterprise_info/ directory.',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),

        // Breadcrumb + actions
        Row(
          children: [
            InkWell(
              onTap: () => _loadFiles(''),
              child: const Text('root',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.accentText,
                      decoration: TextDecoration.underline)),
            ),
            if (_currentPath.isNotEmpty) ...[
              ..._currentPath.split('/').asMap().entries.map((entry) {
                final idx = entry.key;
                final part = entry.value;
                final pathUpTo = _currentPath
                    .split('/')
                    .sublist(0, idx + 1)
                    .join('/');
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(' / ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                    InkWell(
                      onTap: () => _loadFiles(pathUpTo),
                      child: Text(part,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accentText,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                );
              }),
            ],
            const Spacer(),
            if (_currentPath.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_upward,
                    size: 16, color: AppColors.textSecondary),
                onPressed: _navigateUp,
                tooltip: 'Go up',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _loadFiles(_currentPath),
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_loading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_files.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No files',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          _SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _files.asMap().entries.map((entry) {
                final f = entry.value;
                final isLast = entry.key == _files.length - 1;
                final isDir = f['type'] == 'directory';
                final name = (f['name'] ?? '') as String;
                return InkWell(
                  onTap: isDir ? () => _navigateToFolder(name) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                  color: AppColors.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDir
                              ? Icons.folder_outlined
                              : Icons.description_outlined,
                          size: 18,
                          color: isDir
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDir
                                      ? AppColors.accentText
                                      : AppColors.textPrimary)),
                        ),
                        if (f['size'] != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(_formatBytes(f['size'] as int),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                          ),
                        if (f['modified'] != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                                _formatDate(f['modified'] as String),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                          ),
                        if (!isDir)
                          InkWell(
                            onTap: () => _deleteFile(name),
                            child: const Icon(Icons.delete_outline,
                                size: 16, color: AppColors.error),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Shared Helper Widgets / Functions
// ═══════════════════════════════════════════════════════════════

Widget _buildSectionHeader(String title, {String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textTertiary)),
      ],
    ],
  );
}

Widget _buildSaveRow({
  required bool saving,
  required bool saved,
  required VoidCallback onSave,
  bool enabled = true,
}) {
  return Row(
    children: [
      _buildSaveButton(
          saving: saving, saved: saved, onSave: onSave, enabled: enabled),
    ],
  );
}

Widget _buildSaveButton({
  required bool saving,
  required bool saved,
  required VoidCallback onSave,
  bool enabled = true,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElevatedButton(
        onPressed: enabled && !saving ? onSave : null,
        child: Text(saving ? 'Saving...' : 'Save'),
      ),
      if (saved) ...[
        const SizedBox(width: 8),
        const Text('Saved',
            style:
                TextStyle(color: AppColors.success, fontSize: 12)),
      ],
    ],
  );
}

Widget _buildBadge(String text, Color bgColor, {Color? textColor}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textColor ?? bgColor,
      ),
    ),
  );
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate).toLocal();
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return isoDate;
  }
}
