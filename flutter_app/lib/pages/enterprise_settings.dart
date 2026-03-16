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
    'Skills',
    // '知识库',     // 2C 不需要
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
          // _KnowledgeBaseTab(),  // 2C 不需要
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
      _showError('保存公司名称失败');
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
      _showError('保存公司简介失败');
    }
    setState(() => _introSaving = false);
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
        // ── Company Name ──
        _buildSectionHeader('公司名称'),
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
                    hintText: '请输入公司名称',
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
        _buildSectionHeader('公司简介',
            subtitle:
                "描述你公司的使命、产品和文化。这些信息会作为上下文包含在每个 Agent 的对话中。"),
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
                      '# 公司名称\n\n## 关于我们\n在这里描述你的公司...',
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
                    "此内容会出现在每个 Agent 的系统提示词中",
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _introCtl.dispose();
    super.dispose();
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
  bool _testing = false;

  static const _providers = [
    ('anthropic', 'Anthropic'),
    ('openai', 'OpenAI'),
    ('deepseek', 'DeepSeek'),
    ('kimi', 'Kimi (月之暗面)'),
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

  Future<void> _testModel() async {
    final apiKey = _apiKeyCtl.text.trim();
    if (apiKey.isEmpty && _editingModelId != null) {
      _showError('测试需要重新输入 API Key');
      return;
    }
    if (_modelCtl.text.trim().isEmpty || apiKey.isEmpty) {
      _showError('请先填写模型名称和 API Key');
      return;
    }

    setState(() => _testing = true);
    try {
      final resp = await _dio.post('/enterprise/llm-models/test', data: {
        'provider': _provider,
        'model': _modelCtl.text.trim(),
        'api_key': apiKey,
        'base_url': _baseUrlCtl.text.trim().isEmpty ? null : _baseUrlCtl.text.trim(),
      });
      if (!mounted) return;
      final success = resp.data['success'] == true;
      final message = resp.data['message'] as String? ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      _showError('测试请求失败');
    } finally {
      if (mounted) setState(() => _testing = false);
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
                                borderRadius: BorderRadius.circular(12),
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
                            onChanged: (_) => setState(() {}),
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
                      onChanged: (_) => setState(() {}),
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
                      onPressed: _testing ? null : () => setState(() {
                        _showForm = false;
                        _editingModelId = null;
                      }),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _testing || _modelCtl.text.isEmpty || _apiKeyCtl.text.isEmpty
                          ? null
                          : _testModel,
                      child: _testing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary))
                          : const Text('测试'),
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
          ..._models.where((m) => m['id'] != _editingModelId).map(_buildModelCard),
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
            _buildBadge(enabled ? '已启用' : '已禁用',
                enabled ? AppColors.success : AppColors.warning),
            if (vision) ...[
              const SizedBox(width: 6),
              _buildBadge('视觉', const Color(0xFF6366F1)),
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
        title: const Text('删除工具',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('确定删除 "$displayName" 吗？',
            style: const TextStyle(color: AppColors.textSecondary)),
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
      await _dio.delete('/tools/$toolId');
      _loadTools();
    } catch (_) {
      _showError('删除工具失败');
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
          SnackBar(content: Text('已导入 ${tool['name']}')),
        );
      }
    } catch (_) {
      _showError('导入工具失败');
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
            const Text('全局工具',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddMCP = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('MCP 服务器'),
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
                const Text('添加 MCP 服务器',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text('服务器名称',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _mcpNameCtl,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(hintText: '我的 MCP 服务器'),
                ),
                const SizedBox(height: 10),
                const Text('MCP 服务器地址',
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
                          _mcpTesting ? '测试中...' : '测试连接'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _showAddMCP = false;
                        _mcpTestResult = null;
                      }),
                      child: const Text('取消'),
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
                                '连接成功！发现 ${(_mcpTestResult!['tools'] as List?)?.length ?? 0} 个工具',
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
                                        child: const Text('导入'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          )
                        : Text(
                            '连接失败: ${_mcpTestResult!['error'] ?? '未知错误'}',
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
              child: Text('暂无可用工具',
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
                        isMcp ? 'MCP' : '内置',
                        isMcp
                            ? AppColors.accentPrimary
                            : AppColors.bgTertiary,
                        textColor: isMcp
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 4),
                        _buildBadge('默认', AppColors.success,
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
                tooltip: '删除',
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
      final data = await ApiService.instance.listSkillFiles(path: path);
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

  void _viewFile(String name) {
    final filePath = _currentPath.isEmpty ? name : '$_currentPath/$name';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SkillFileViewer(filePath: filePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Skills 注册表',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          '管理全局技能。每个技能是一个包含 SKILL.md 文件的文件夹。'
          "创建 Agent 时选择的技能会被复制到 Agent 的工作区。",
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
              child: Text('暂无技能',
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
        const Text('技能文件',
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
              child: const Text('根目录',
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
                tooltip: '返回上级',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _loadFiles(_currentPath),
              tooltip: '刷新',
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
              child: Text('空目录',
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
                final isDir = f['is_dir'] == true || f['type'] == 'directory';
                final name = (f['name'] ?? '') as String;
                return InkWell(
                  onTap: isDir ? () => _navigateToFolder(name) : () => _viewFile(name),
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

// ─── Skill File Viewer (bottom sheet) ─────────────────────────
class _SkillFileViewer extends StatefulWidget {
  final String filePath;
  const _SkillFileViewer({required this.filePath});
  @override
  State<_SkillFileViewer> createState() => _SkillFileViewerState();
}

class _SkillFileViewerState extends State<_SkillFileViewer> {
  String _content = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.readSkillFile(widget.filePath);
      if (mounted) {
        setState(() {
          _content = (data['content'] ?? '') as String;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(fileName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                    ? Center(child: Text('加载失败: $_error',
                        style: const TextStyle(color: AppColors.error, fontSize: 13)))
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _content,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
          ),
        ],
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
      _showError('保存配额失败');
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
      _showError('保存用户配额失败');
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
        const Text('默认用户配额',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          '这些默认值适用于新注册用户，不影响现有用户。',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),

        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Conversation limits
              const Text('对话限制',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuotaField(
                      '消息上限',
                      '每个周期最大消息数',
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
                        const Text('消息周期',
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
                                    child: Text('永久')),
                                DropdownMenuItem(
                                    value: 'daily',
                                    child: Text('每天')),
                                DropdownMenuItem(
                                    value: 'weekly',
                                    child: Text('每周')),
                                DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('每月')),
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
              const Text('Agent 限制',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuotaField(
                      '最大 Agent 数',
                      '用户可创建的 Agent 数量',
                      _defaultMaxAgents.toString(),
                      (v) => _defaultMaxAgents =
                          int.tryParse(v) ?? _defaultMaxAgents,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuotaField(
                      'Agent 存活时间（小时）',
                      'Agent 自动过期时间',
                      _defaultAgentTtlHours.toString(),
                      (v) => _defaultAgentTtlHours =
                          int.tryParse(v) ?? _defaultAgentTtlHours,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuotaField(
                      '每日 LLM 调用 / Agent',
                      '每个 Agent 每天最大 LLM 调用次数',
                      _defaultMaxLlmCallsPerDay.toString(),
                      (v) => _defaultMaxLlmCallsPerDay =
                          int.tryParse(v) ?? _defaultMaxLlmCallsPerDay,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Text('系统',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                child: _buildQuotaField(
                  '最小心跳间隔（分钟）',
                  '所有 Agent 的最小心跳间隔',
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
        const Text('用户',
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
              child: Text('暂无用户',
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
                          child: Text('用户',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('角色',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('消息上限',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary))),
                      Expanded(
                          flex: 2,
                          child: Text('最大 Agent 数',
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
        title: const Text('删除文件',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('确定删除 "$name" 吗？',
            style: const TextStyle(color: AppColors.textSecondary)),
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
      await _dio.delete('/enterprise/knowledge-base/files',
          queryParameters: {'path': path});
      _loadFiles(_currentPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除文件失败')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('企业知识库',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          '所有 Agent 可通过 enterprise_info/ 目录访问的共享文件。',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),

        // Breadcrumb + actions
        Row(
          children: [
            InkWell(
              onTap: () => _loadFiles(''),
              child: const Text('根目录',
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
                tooltip: '返回上级',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _loadFiles(_currentPath),
              tooltip: '刷新',
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
              child: Text('暂无文件',
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
                final isDir = f['is_dir'] == true || f['type'] == 'directory';
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
        child: Text(saving ? '保存中...' : '保存'),
      ),
      if (saved) ...[
        const SizedBox(width: 8),
        const Text('已保存',
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
