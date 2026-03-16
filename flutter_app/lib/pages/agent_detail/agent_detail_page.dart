import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/app_lifecycle.dart';
import '../../services/api.dart';
import 'shared_widgets.dart';

part 'tab_overview.dart';
part 'tab_tasks.dart';
part 'tab_mind.dart';
part 'tab_tools.dart';
part 'tab_skills.dart';
part 'tab_workspace.dart';
part 'tab_activity.dart';
part 'tab_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AgentDetailPage — full-featured multi-tab agent detail screen
// Port of React AgentDetail.tsx
// ─────────────────────────────────────────────────────────────────────────────

class AgentDetailPage extends ConsumerStatefulWidget {
  final String agentId;
  const AgentDetailPage({super.key, required this.agentId});

  @override
  ConsumerState<AgentDetailPage> createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends ConsumerState<AgentDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService.instance;

  // ── Agent core data ──────────────────────────────────────
  Map<String, dynamic>? _agent;
  Map<String, dynamic>? _metrics;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  // ── Overview ─────────────────────────────────────────────
  List<dynamic> _recentActivity = [];

  // ── Tasks ────────────────────────────────────────────────
  List<dynamic> _tasks = [];
  bool _loadingTasks = false;
  String _taskFilter = 'pending';
  // ── Schedules ────────────────────────────────────────────
  List<dynamic> _schedules = [];

  // ── Mind ─────────────────────────────────────────────────
  String? _soulContent;
  bool _editingSoul = false;
  bool _savingSoul = false;
  final _soulController = TextEditingController();
  List<dynamic> _memoryFiles = [];
  bool _loadingMind = false;
  String? _heartbeatContent;
  bool _soulExpanded = false;
  bool _heartbeatExpanded = false;
  bool _memoryExpanded = false;

  // ── Tools ────────────────────────────────────────────────
  List<dynamic> _platformTools = [];
  List<dynamic> _agentTools = [];
  bool _loadingTools = false;

  // ── Skills ───────────────────────────────────────────────
  List<dynamic> _skillFiles = [];
  bool _loadingSkills = false;
  String? _viewingSkillContent;
  String? _viewingSkillName;
  String? _skillSubFolder;        // non-null = viewing files inside a skill folder
  List<dynamic> _skillSubFiles = []; // files inside the sub folder

  // ── Workspace ────────────────────────────────────────────
  List<dynamic> _workspaceFiles = [];
  String _currentPath = '';
  bool _loadingWorkspace = false;
  String? _viewingFileContent;
  String? _viewingFileName;

  // ── Activity ─────────────────────────────────────────────
  List<dynamic> _activities = [];
  bool _loadingActivity = false;
  String _logFilter = 'all';
  String? _expandedLogId;

  // ── Skill presets ──────────────────────────────────────────
  List<dynamic> _skillPresets = [];
  bool _showSkillPresets = false;

  // ── Tool config ────────────────────────────────────────────
  String? _expandedToolId;
  int _toolSection = 0; // 0=platform, 1=agent-installed
  final _toolConfigControllers = <String, TextEditingController>{};

  // ── Header inline edit ─────────────────────────────────────
  bool _editingName = false;
  final _nameController = TextEditingController();
  bool _savingName = false;

  // ── Settings ─────────────────────────────────────────────
  final _modelCtrl = TextEditingController();
  final _fallbackModelCtrl = TextEditingController();
  final _maxTokensCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _contextWindowCtrl = TextEditingController(text: '100');
  final _maxToolRoundsCtrl = TextEditingController(text: '50');
  final _dailyTokenCtrl = TextEditingController();
  final _monthlyTokenCtrl = TextEditingController();
  final _heartbeatIntervalCtrl = TextEditingController(text: '120');
  final _heartbeatActiveHoursCtrl = TextEditingController(text: '09:00-18:00');
  List<dynamic> _llmModels = [];
  Map<String, dynamic>? _channelConfig;
  int _minHeartbeatInterval = 120;
  bool _loadingSettings = false;
  bool _savingSettings = false;
  bool _showDeleteConfirm = false;
  bool _showCreateChannel = false;
  String _newChannelType = 'feishu';
  final _channelTokenCtrl = TextEditingController();
  final _channelIdCtrl = TextEditingController();
  final _channelSecretCtrl = TextEditingController();
  final _channelEncryptKeyCtrl = TextEditingController();
  final _channelPublicKeyCtrl = TextEditingController();


  static const _tabLabels = [
    '状态',
    '任务',
    '思维',
    '工具',
    '技能',
    '工作区',
    '活动',
    '设置',
  ];

  // ─── Lifecycle ───────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchAgent();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) {
        if (!AppLifecycle.instance.isActive) return;
        if (mounted) _fetchAgentSilent();
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _taskPollTimer?.cancel();
    _tabController.dispose();
    _soulController.dispose();
    _modelCtrl.dispose();
    _fallbackModelCtrl.dispose();
    _maxTokensCtrl.dispose();
    _temperatureCtrl.dispose();
    _contextWindowCtrl.dispose();
    _maxToolRoundsCtrl.dispose();
    _dailyTokenCtrl.dispose();
    _monthlyTokenCtrl.dispose();
    _heartbeatIntervalCtrl.dispose();
    _heartbeatActiveHoursCtrl.dispose();
    _nameController.dispose();
    _channelTokenCtrl.dispose();
    _channelIdCtrl.dispose();
    _channelSecretCtrl.dispose();
    _channelEncryptKeyCtrl.dispose();
    _channelPublicKeyCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _loadTabData(_tabController.index);
  }

  void _loadTabData(int idx) {
    switch (idx) {
      case 0:
        _fetchOverviewData();
        break;
      case 1:
        _fetchTasks();
        _fetchSchedules();
        break;
      case 2:
        _fetchMindData();
        break;
      case 3:
        _fetchToolsData();
        break;
      case 4:
        _fetchSkillsData();
        break;
      case 5:
        _fetchWorkspaceFiles();
        break;
      case 6:
        _fetchActivity();
        break;
      case 7:
        _fetchSettingsData();
        break;
    }
  }

  // ─── Data fetching ───────────────────────────────────────

  Future<void> _fetchAgent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final agent = await _api.getAgent(widget.agentId);
      if (!mounted) return;
      setState(() {
        _agent = agent;
        _loading = false;
      });
      _fetchOverviewData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchAgentSilent() async {
    try {
      final agent = await _api.getAgent(widget.agentId);
      if (!mounted) return;
      setState(() => _agent = agent);
    } catch (_) {}
  }

  Future<void> _fetchOverviewData() async {
    try {
      final results = await Future.wait([
        _api.getAgentMetrics(widget.agentId).catchError((_) => <String, dynamic>{}),
        _api.listActivity(widget.agentId, limit: 5).catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _metrics = results[0] as Map<String, dynamic>?;
        _recentActivity = results[1] as List<dynamic>;
      });
    } catch (_) {}
  }

  Future<void> _fetchTasks() async {
    setState(() => _loadingTasks = true);
    try {
      final tasks = await _api.listTasks(widget.agentId);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTasks = false);
      _showSnack('加载任务失败: ${_errMsg(e)}');
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      final s = await _api.listSchedules(widget.agentId);
      if (mounted) setState(() => _schedules = s);
    } catch (_) {}
  }

  Future<void> _fetchMindData() async {
    setState(() => _loadingMind = true);
    try {
      final results = await Future.wait([
        _api.readFile(widget.agentId, 'soul.md').catchError((_) => <String, dynamic>{}),
        _api.listFiles(widget.agentId, path: 'memory').catchError((_) => <dynamic>[]),
        _api.readFile(widget.agentId, 'HEARTBEAT.md').catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _soulContent = (results[0] as Map<String, dynamic>)['content'] as String?;
        _soulController.text = _soulContent ?? '';
        _memoryFiles = results[1] as List<dynamic>;
        _heartbeatContent = (results[2] as Map<String, dynamic>)['content'] as String?;
        _loadingMind = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMind = false);
    }
  }

  Future<void> _fetchToolsData() async {
    setState(() => _loadingTools = true);
    try {
      List<dynamic> tools;
      try {
        tools = await _api.listAgentToolsWithConfig(widget.agentId);
      } catch (_) {
        // Fallback to basic endpoint
        tools = await _api.listAgentTools(widget.agentId).catchError((_) => <dynamic>[]);
      }
      if (!mounted) return;
      final platform = <dynamic>[];
      final installed = <dynamic>[];
      for (final t in tools) {
        final m = t as Map<String, dynamic>;
        if (m['source'] == 'user_installed') {
          installed.add(m);
        } else {
          platform.add(m);
        }
      }
      setState(() {
        _platformTools = platform;
        _agentTools = installed;
        _loadingTools = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTools = false);
    }
  }

  Future<void> _fetchSkillsData() async {
    setState(() => _loadingSkills = true);
    try {
      final files = await _api.listFiles(widget.agentId, path: 'skills').catchError((_) => <dynamic>[]);
      if (!mounted) return;
      setState(() {
        _skillFiles = files;
        _loadingSkills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSkills = false);
    }
  }

  Future<void> _fetchWorkspaceFiles([String path = '']) async {
    setState(() {
      _loadingWorkspace = true;
      _currentPath = path;
      _viewingFileContent = null;
      _viewingFileName = null;
    });
    try {
      final files = await _api.listFiles(widget.agentId, path: path);
      if (!mounted) return;
      setState(() {
        _workspaceFiles = files;
        _loadingWorkspace = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingWorkspace = false);
      _showSnack('加载文件失败: ${_errMsg(e)}');
    }
  }

  Future<void> _fetchActivity() async {
    setState(() => _loadingActivity = true);
    try {
      final acts = await _api.listActivity(widget.agentId, limit: 100);
      if (!mounted) return;
      setState(() {
        _activities = acts;
        _loadingActivity = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingActivity = false);
      _showSnack('加载活动失败: ${_errMsg(e)}');
    }
  }

  Future<void> _fetchSkillPresets() async {
    try {
      final skills = await _api.listSkills();
      if (!mounted) return;
      setState(() => _skillPresets = skills);
    } catch (_) {}
  }

  Future<void> _importSkillPreset(String skillId) async {
    try {
      await _api.importSkill(widget.agentId, skillId);
      _fetchSkillsData();
      _showSnack('技能已导入');
    } catch (e) {
      _showSnack('导入失败: ${_errMsg(e)}');
    }
  }

  Future<void> _fetchSettingsData() async {
    setState(() => _loadingSettings = true);
    try {
      final results = await Future.wait([
        _api.listLlmModels().catchError((_) => <dynamic>[]),
        _api.getChannel(widget.agentId),
        _api.getTenantQuotas().catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final agent = _agent ?? {};
      final quotas = results[2] as Map<String, dynamic>;
      setState(() {
        _llmModels = results[0] as List<dynamic>;
        _channelConfig = results[1] as Map<String, dynamic>?;
        _minHeartbeatInterval = (quotas['min_heartbeat_interval_minutes'] as int?) ?? 120;
        _modelCtrl.text = (agent['primary_model_id'] ?? agent['model'] ?? '') as String;
        _fallbackModelCtrl.text = (agent['fallback_model_id'] ?? agent['fallback_model'] ?? '') as String;
        _maxTokensCtrl.text = (agent['max_tokens'] ?? 4096).toString();
        _temperatureCtrl.text = (agent['temperature'] ?? 0.7).toString();
        _contextWindowCtrl.text = (agent['context_window'] ?? 100).toString();
        _maxToolRoundsCtrl.text = (agent['max_tool_rounds'] ?? 50).toString();
        _dailyTokenCtrl.text = (agent['daily_token_limit'] ?? '').toString();
        _monthlyTokenCtrl.text = (agent['monthly_token_limit'] ?? '').toString();
        _heartbeatIntervalCtrl.text = '${agent['heartbeat_interval_minutes'] ?? 120}';
        _heartbeatActiveHoursCtrl.text = (agent['heartbeat_active_hours'] as String?) ?? '09:00-18:00';
        _loadingSettings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSettings = false);
    }
  }

  // ─── Actions ─────────────────────────────────────────────

  Future<void> _deleteAgent() async {
    final confirmed = await _showConfirmDialog(
      '删除智能体',
      '确认永久删除这个智能体吗？此操作不可撤销。',
    );
    if (confirmed != true) return;
    try {
      await _api.deleteAgent(widget.agentId);
      if (!mounted) return;
      context.go('/dashboard');
      _showSnack('智能体已删除');
    } catch (e) {
      _showSnack('删除失败: ${_errMsg(e)}');
    }
  }


  Future<void> _saveSoulMd() async {
    setState(() => _savingSoul = true);
    try {
      await _api.writeFile(widget.agentId, 'soul.md', _soulController.text);
      if (!mounted) return;
      setState(() {
        _soulContent = _soulController.text;
        _editingSoul = false;
        _savingSoul = false;
      });
      _showSnack('soul.md 已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSoul = false);
      _showSnack('保存 soul.md 失败: ${_errMsg(e)}');
    }
  }

  Future<void> _toggleTool(String toolId, bool enabled) async {
    // Optimistic update
    setState(() {
      for (final list in [_platformTools, _agentTools]) {
        for (int i = 0; i < list.length; i++) {
          final m = list[i] as Map<String, dynamic>;
          if (m['id']?.toString() == toolId) {
            list[i] = {...m, 'enabled': enabled};
            break;
          }
        }
      }
    });
    try {
      await _api.toggleAgentTool(widget.agentId, toolId, enabled);
    } catch (e) {
      // Revert on failure
      _fetchToolsData();
      if (!mounted) return;
      _showSnack('工具开关失败: ${_errMsg(e)}');
    }
  }

  Widget _buildToolConfigFields(String toolId, Map<String, dynamic> schema, {Map<String, dynamic>? agentConfig, Map<String, dynamic>? globalConfig}) {
    final fields = (schema['fields'] as List?) ?? [];
    if (fields.isEmpty) return const SizedBox.shrink();
    final merged = <String, dynamic>{...(globalConfig ?? {}), ...(agentConfig ?? {})};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('配置', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...fields.map((f) {
          final field = f as Map<String, dynamic>;
          final key = field['name'] as String? ?? field['key'] as String? ?? '';
          final label = field['label'] as String? ?? key;
          final isPassword = field['type'] == 'password';
          final ctrlKey = '${toolId}_$key';
          final savedValue = merged[key]?.toString() ?? field['default']?.toString() ?? '';
          _toolConfigControllers[ctrlKey] ??= TextEditingController(text: savedValue);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _toolConfigControllers[ctrlKey],
              obscureText: isPassword,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                hintText: field['placeholder'] as String?,
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () async {
              final config = <String, dynamic>{};
              for (final f in fields) {
                final field = f as Map<String, dynamic>;
                final key = field['name'] as String? ?? field['key'] as String? ?? '';
                final ctrlKey = '${toolId}_$key';
                config[key] = _toolConfigControllers[ctrlKey]?.text ?? '';
              }
              try {
                await _api.updateToolConfig(widget.agentId, toolId, config);
                _showSnack('工具配置已保存');
              } catch (e) {
                _showSnack('保存失败: ${_errMsg(e)}');
              }
            },
            child: const Text('保存配置'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _savingSettings = true);
    try {
      final data = <String, dynamic>{};
      if (_modelCtrl.text.isNotEmpty) data['primary_model_id'] = _modelCtrl.text;
      if (_fallbackModelCtrl.text.isNotEmpty) {
        data['fallback_model_id'] = _fallbackModelCtrl.text;
      }
      final maxTokens = int.tryParse(_maxTokensCtrl.text);
      if (maxTokens != null) data['max_tokens'] = maxTokens;
      final temp = double.tryParse(_temperatureCtrl.text);
      if (temp != null) data['temperature'] = temp;
      final ctxWindow = int.tryParse(_contextWindowCtrl.text);
      if (ctxWindow != null) data['context_window'] = ctxWindow;
      final maxToolRounds = int.tryParse(_maxToolRoundsCtrl.text);
      if (maxToolRounds != null) data['max_tool_rounds'] = maxToolRounds;
      final dailyLimit = int.tryParse(_dailyTokenCtrl.text);
      if (dailyLimit != null) data['daily_token_limit'] = dailyLimit;
      final monthlyLimit = int.tryParse(_monthlyTokenCtrl.text);
      if (monthlyLimit != null) data['monthly_token_limit'] = monthlyLimit;
      await _api.updateAgent(widget.agentId, data);
      await _fetchAgentSilent();
      if (!mounted) return;
      setState(() => _savingSettings = false);
      _showSnack('设置已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingSettings = false);
      _showSnack('保存设置失败: ${_errMsg(e)}');
    }
  }

  Future<void> _openWorkspaceFile(Map<String, dynamic> file) async {
    final name = file['name'] as String? ?? '';
    final isDir = file['is_directory'] == true || file['type'] == 'directory';
    if (isDir) {
      final newPath = _currentPath.isEmpty ? name : '$_currentPath/$name';
      _fetchWorkspaceFiles(newPath);
      return;
    }
    try {
      final filePath = _currentPath.isEmpty ? name : '$_currentPath/$name';
      final res = await _api.readFile(widget.agentId, filePath);
      if (!mounted) return;
      setState(() {
        _viewingFileContent = res['content'] as String?;
        _viewingFileName = name;
      });
    } catch (e) {
      _showSnack('读取文件失败: ${_errMsg(e)}');
    }
  }

  Future<void> _openSkillFile(Map<String, dynamic> file) async {
    final name = file['name'] as String? ?? '';
    final isDir = file['is_dir'] == true;
    if (isDir) {
      // Navigate into the folder — list its contents
      try {
        final subFiles = await _api.listFiles(widget.agentId, path: 'skills/$name');
        if (!mounted) return;
        setState(() {
          _skillSubFolder = name;
          _skillSubFiles = subFiles;
        });
      } catch (e) {
        if (!mounted) return;
        _showSnack('打开技能文件夹失败: ${_errMsg(e)}');
      }
    } else {
      // Flat .md file — read and show content directly
      try {
        final res = await _api.readFile(widget.agentId, 'skills/$name');
        if (!mounted) return;
        setState(() {
          _viewingSkillContent = res['content'] as String?;
          _viewingSkillName = name;
        });
      } catch (e) {
        if (!mounted) return;
        _showSnack('读取技能文件失败: ${_errMsg(e)}');
      }
    }
  }

  Future<void> _openSkillSubFile(Map<String, dynamic> file) async {
    final name = file['name'] as String? ?? '';
    final isDir = file['is_dir'] == true;
    final path = 'skills/$_skillSubFolder/$name';
    if (isDir) {
      // Navigate deeper into sub-folder
      try {
        final subFiles = await _api.listFiles(widget.agentId, path: path);
        if (!mounted) return;
        setState(() {
          _skillSubFolder = '$_skillSubFolder/$name';
          _skillSubFiles = subFiles;
        });
      } catch (e) {
        if (!mounted) return;
        _showSnack('打开文件夹失败: ${_errMsg(e)}');
      }
    } else {
      try {
        final res = await _api.readFile(widget.agentId, path);
        if (!mounted) return;
        setState(() {
          _viewingSkillContent = res['content'] as String?;
          _viewingSkillName = '$_skillSubFolder/$name';
        });
      } catch (e) {
        if (!mounted) return;
        _showSnack('读取文件失败: ${_errMsg(e)}');
      }
    }
  }

  Future<void> _deleteSkillFile(String name) async {
    final confirmed = await _showConfirmDialog(
      '删除技能',
      '确认删除 "$name" 吗？',
    );
    if (confirmed != true) return;
    try {
      await _api.deleteFile(widget.agentId, 'skills/$name');
      _showSnack('技能已删除');
      setState(() {
        _skillSubFolder = null;
        _skillSubFiles = [];
        _viewingSkillContent = null;
        _viewingSkillName = null;
      });
      _fetchSkillsData();
    } catch (e) {
      _showSnack('删除技能失败: ${_errMsg(e)}');
    }
  }

  Future<void> _deleteWorkspaceFile(String name) async {
    final confirmed = await _showConfirmDialog(
      '删除文件',
      '确认删除 "$name" 吗？',
    );
    if (confirmed != true) return;
    try {
      final filePath = _currentPath.isEmpty ? name : '$_currentPath/$name';
      await _api.deleteFile(widget.agentId, filePath);
      _showSnack('文件已删除');
      _fetchWorkspaceFiles(_currentPath);
    } catch (e) {
      _showSnack('删除文件失败: ${_errMsg(e)}');
    }
  }

  Future<void> _readMemoryFile(String name) async {
    try {
      final res = await _api.readFile(widget.agentId, 'memory/$name');
      if (!mounted) return;
      _showContentDialog(name, res['content'] as String? ?? '(空)');
    } catch (e) {
      _showSnack('读取记忆文件失败: ${_errMsg(e)}');
    }
  }

  Future<void> _deleteChannel() async {
    final confirmed = await _showConfirmDialog(
      '删除通道',
      '确认删除通道配置吗？',
    );
    if (confirmed != true) return;
    try {
      await _api.deleteChannel(widget.agentId);
      _showSnack('通道已删除');
      _fetchSettingsData();
    } catch (e) {
      _showSnack('删除通道失败: ${_errMsg(e)}');
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    final confirmed = await _showConfirmDialog(
      '删除计划',
      '确认删除此计划吗？',
    );
    if (confirmed != true) return;
    try {
      await _api.deleteSchedule(widget.agentId, scheduleId);
      _showSnack('计划已删除');
      _fetchSchedules();
    } catch (e) {
      _showSnack('删除计划失败: ${_errMsg(e)}');
    }
  }

  Future<void> _saveAgentName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _savingName = true);
    try {
      await _api.updateAgent(widget.agentId, {'name': name});
      await _fetchAgentSilent();
      if (!mounted) return;
      setState(() {
        _editingName = false;
        _savingName = false;
      });
      _showSnack('名称已更新');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingName = false);
      _showSnack('更新名称失败: ${_errMsg(e)}');
    }
  }

  Timer? _taskPollTimer;

  Future<void> _triggerTask(String taskId) async {
    try {
      await _api.triggerTask(widget.agentId, taskId);
      _showSnack('任务已触发，执行中...');
      setState(() => _taskFilter = 'doing');
      _fetchTasks();
      // Poll every 3s until task leaves 'doing'
      _taskPollTimer?.cancel();
      _taskPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (!mounted) { timer.cancel(); return; }
        await _fetchTasks();
        final stillDoing = _tasks.any((t) => (t as Map)['id'] == taskId && (t['status'] == 'doing' || t['status'] == 'running'));
        if (!stillDoing) {
          timer.cancel();
          if (mounted) setState(() => _taskFilter = 'done');
        }
      });
    } catch (e) {
      _showSnack('触发任务失败: ${_errMsg(e)}');
    }
  }

  Future<void> _triggerSchedule(String scheduleId) async {
    try {
      await _api.triggerSchedule(widget.agentId, scheduleId);
      _showSnack('计划已手动触发');
      _fetchSchedules();
    } catch (e) {
      _showSnack('触发计划失败: ${_errMsg(e)}');
    }
  }


  Future<void> _createChannel() async {
    try {
      final data = <String, dynamic>{'type': _newChannelType};
      if (_channelTokenCtrl.text.trim().isNotEmpty) {
        data['bot_token'] = _channelTokenCtrl.text.trim();
      }
      if (_channelIdCtrl.text.trim().isNotEmpty) {
        data['channel_id'] = _channelIdCtrl.text.trim();
      }
      if (_channelSecretCtrl.text.trim().isNotEmpty) {
        data['app_secret'] = _channelSecretCtrl.text.trim();
      }
      await _api.createChannel(widget.agentId, data);
      _channelTokenCtrl.clear();
      _channelIdCtrl.clear();
      _channelSecretCtrl.clear();
      if (!mounted) return;
      setState(() => _showCreateChannel = false);
      _showSnack('通道已创建');
      _fetchSettingsData();
    } catch (e) {
      _showSnack('创建通道失败: ${_errMsg(e)}');
    }
  }

  Future<void> _uploadWorkspaceFile() async {
    // Use file_picker to select a file
    try {
      final result = await _pickFile();
      if (result == null) return;
      await _api.uploadFileBytes(
        widget.agentId,
        result['bytes'] as List<int>,
        result['name'] as String,
        path: _currentPath.isEmpty ? 'workspace' : 'workspace/$_currentPath',
      );
      _showSnack('文件已上传');
      _fetchWorkspaceFiles(_currentPath);
    } catch (e) {
      _showSnack('上传失败: ${_errMsg(e)}');
    }
  }

  Future<Map<String, dynamic>?> _pickFile() async {
    // Simple approach using file_picker isn't available, so use a name+content dialog for text files
    // For now, show create file dialog
    return _showCreateFileDialog();
  }

  Future<Map<String, dynamic>?> _showCreateFileDialog() async {
    final nameCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('新建文件', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: '文件名', hintText: 'example.md', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                maxLines: 8,
                decoration: const InputDecoration(labelText: '内容', isDense: true, alignLabelWithHint: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'name': nameCtrl.text.trim(), 'content': contentCtrl.text});
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    contentCtrl.dispose();
    return result;
  }

  Future<void> _createWorkspaceFile() async {
    final result = await _showCreateFileDialog();
    if (result == null) return;
    try {
      final path = _currentPath.isEmpty ? result['name'] : '$_currentPath/${result['name']}';
      await _api.writeFile(widget.agentId, path, result['content'] as String);
      _showSnack('文件已创建');
      _fetchWorkspaceFiles(_currentPath);
    } catch (e) {
      _showSnack('创建文件失败: ${_errMsg(e)}');
    }
  }

  Future<void> _createWorkspaceFolder() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('新建文件夹', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: const InputDecoration(labelText: '文件夹名', isDense: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, nameCtrl.text.trim());
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null) return;
    try {
      // Create folder by writing a placeholder .gitkeep file inside it
      final path = _currentPath.isEmpty ? '$name/.gitkeep' : '$_currentPath/$name/.gitkeep';
      await _api.writeFile(widget.agentId, path, '');
      _showSnack('文件夹已创建');
      _fetchWorkspaceFiles(_currentPath);
    } catch (e) {
      _showSnack('创建文件夹失败: ${_errMsg(e)}');
    }
  }

  Future<void> _editWorkspaceFile() async {
    if (_viewingFileContent == null || _viewingFileName == null) return;
    final ctrl = TextEditingController(text: _viewingFileContent);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('编辑 $_viewingFileName', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) { ctrl.dispose(); return; }
    try {
      final path = _currentPath.isEmpty ? _viewingFileName! : '$_currentPath/$_viewingFileName';
      await _api.writeFile(widget.agentId, path, ctrl.text);
      setState(() => _viewingFileContent = ctrl.text);
      _showSnack('文件已保存');
    } catch (e) {
      _showSnack('保存失败: ${_errMsg(e)}');
    }
    ctrl.dispose();
  }

  Future<void> _createSkillFile() async {
    final nameCtrl = TextEditingController(text: 'new_skill.md');
    final contentCtrl = TextEditingController(text: '# Skill: 新技能\n\n## 触发条件\n当用户请求...\n\n## 执行步骤\n1. ...\n2. ...\n\n## 注意事项\n- ...\n');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('新建技能', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(labelText: '文件名', isDense: true),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: TextField(
                  controller: contentCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(labelText: '内容', isDense: true, alignLabelWithHint: true, border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, {'name': nameCtrl.text.trim(), 'content': contentCtrl.text});
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    contentCtrl.dispose();
    if (result == null) return;
    try {
      await _api.writeFile(widget.agentId, 'skills/${result['name']}', result['content'] as String);
      _showSnack('技能已创建');
      _fetchSkillsData();
    } catch (e) {
      _showSnack('创建技能失败: ${_errMsg(e)}');
    }
  }

  Future<void> _editSkillFile() async {
    if (_viewingSkillContent == null || _viewingSkillName == null) return;
    final ctrl = TextEditingController(text: _viewingSkillContent);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('编辑 $_viewingSkillName', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (saved != true) { ctrl.dispose(); return; }
    try {
      await _api.writeFile(widget.agentId, 'skills/$_viewingSkillName', ctrl.text);
      setState(() => _viewingSkillContent = ctrl.text);
      _showSnack('技能已保存');
    } catch (e) {
      _showSnack('保存失败: ${_errMsg(e)}');
    }
    ctrl.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────


  static const _segmentLabelMap = {
    'all': '全部',
    'pending': '待处理',
    'running': '进行中',
    'completed': '已完成',
    'failed': '失败',
    'user': '用户',
    'system': '系统',
    'error': '错误',
  };

  String _segmentLabel(String key) {
    return _segmentLabelMap[key] ?? (key[0].toUpperCase() + key.substring(1));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  String _errMsg(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) return detail.map((d) => d is Map ? (d['msg'] ?? d.toString()) : d.toString()).join('; ');
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      final sc = e.response?.statusCode;
      return sc != null ? 'HTTP $sc' : '网络错误';
    }
    return e.toString();
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showContentDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _fmtTs(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt = DateTime.parse(ts.toString());
      return DateFormat('MMM d, yyyy HH:mm').format(dt.toLocal());
    } catch (_) {
      return ts.toString();
    }
  }

  String _fmtRelative(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}秒前';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 30) return '${diff.inDays}天前';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }



  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary),
        ),
      );
    }

    if (_error != null || _agent == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error ?? '未找到 Agent',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchAgent, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final agent = _agent!;
    final name = agent['name'] as String? ?? '未命名 Agent';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: _editingName
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _saveAgentName(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: _savingName
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check, color: AppColors.success, size: 20),
                    onPressed: _savingName ? null : _saveAgentName,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
                    onPressed: () => setState(() => _editingName = false),
                  ),
                ],
              )
            : Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        _nameController.text = name;
                        setState(() => _editingName = true);
                      },
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
        actions: const [],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.accentPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(agent),
          _buildTasksTab(),
          _buildMindTab(),
          _buildToolsTab(),
          _buildSkillsTab(),
          _buildWorkspaceTab(),
          _buildActivityTab(),
          _buildSettingsTab(agent),
        ],
      ),
    );
  }

  // ─── Common widgets ──────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _codeBlock(String? content, String emptyMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        child: SelectableText(
          content?.isNotEmpty == true ? content! : emptyMsg,
          style: TextStyle(
            color: content?.isNotEmpty == true ? AppColors.textSecondary : AppColors.textTertiary,
            fontSize: 13,
            fontFamily: 'monospace',
            fontStyle: content?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDateTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  List<Widget> _buildAutonomyPolicyRows(Map<String, dynamic> agent) {
    final policy = (agent['autonomy_policy'] as Map<String, dynamic>?) ?? {};
    const fields = [
      {'key': 'read_files', 'label': '读取文件'},
      {'key': 'write_workspace_files', 'label': '写入工作区文件'},
      {'key': 'delete_files', 'label': '删除文件'},
      {'key': 'send_feishu_message', 'label': '发送消息'},
      {'key': 'web_search', 'label': '网络搜索'},
      {'key': 'manage_tasks', 'label': '管理任务'},
    ];
    const levelLabels = {'L1': '自动', 'L2': '通知', 'L3': '审批'};
    return fields.map((f) {
      final key = f['key']!;
      final label = f['label']!;
      final current = (policy[key] as String?) ?? 'L1';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                value: current,
                isDense: true,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                dropdownColor: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                items: levelLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} ${e.value}'))).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final updated = Map<String, dynamic>.from(policy);
                  updated[key] = v;
                  await _api.updateAgent(widget.agentId, {'autonomy_policy': updated});
                  _fetchAgentSilent();
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _radioOption(String value, String label, String groupValue, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            activeColor: AppColors.accentPrimary,
            onChanged: (v) { if (v != null) onChanged(v); },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _miniSpinner() {
    return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
  }

  Widget _segmentedControl({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
    bool fullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == selected;
          return Expanded(
            flex: fullWidth ? 1 : 0,
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.bgPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 1))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _segmentLabel(opt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
