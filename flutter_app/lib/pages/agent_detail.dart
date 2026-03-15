import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../core/app_lifecycle.dart';
import '../services/api.dart';

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
  bool _showCreateTask = false;
  final _taskTitleCtrl = TextEditingController();
  final _taskDescCtrl = TextEditingController();
  String _taskPriority = 'medium';
  bool _creatingTask = false;
  String _taskFilter = 'all';
  String? _selectedTaskId;
  List<dynamic> _taskLogs = [];

  // ── Schedules ────────────────────────────────────────────
  List<dynamic> _schedules = [];

  // ── Pulse ────────────────────────────────────────────────
  String? _agendaContent;
  List<dynamic> _triggers = [];
  String? _monologueContent;
  String? _taskHistoryContent;
  bool _loadingPulse = false;
  String _pulseSection = 'agenda';

  // ── Mind ─────────────────────────────────────────────────
  String? _soulContent;
  bool _editingSoul = false;
  bool _savingSoul = false;
  final _soulController = TextEditingController();
  List<dynamic> _memoryFiles = [];
  bool _loadingMind = false;
  String? _heartbeatContent;

  // ── Tools ────────────────────────────────────────────────
  List<dynamic> _platformTools = [];
  List<dynamic> _agentTools = [];
  bool _loadingTools = false;

  // ── Skills ───────────────────────────────────────────────
  List<dynamic> _skillFiles = [];
  bool _loadingSkills = false;
  String? _viewingSkillContent;
  String? _viewingSkillName;

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

  // ── Relationships ──────────────────────────────────────────
  List<dynamic> _humanRelationships = [];
  List<dynamic> _agentRelationships = [];
  bool _loadingRelationships = false;
  List<dynamic> _allAgentsList = [];

  // ── Skill presets ──────────────────────────────────────────
  List<dynamic> _skillPresets = [];
  bool _showSkillPresets = false;

  // ── Tool config ────────────────────────────────────────────
  String? _expandedToolId;
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
  List<dynamic> _llmModels = [];
  Map<String, dynamic>? _channelConfig;
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

  // ── Schedule creation ────────────────────────────────────
  bool _showCreateSchedule = false;
  final _scheduleNameCtrl = TextEditingController();
  final _scheduleCronCtrl = TextEditingController();
  String _scheduleFrequency = 'daily';
  bool _creatingSchedule = false;

  static const _tabLabels = [
    '状态',
    '任务',
    '动态',
    '思维',
    '工具',
    '技能',
    '关系',
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
    _tabController.dispose();
    _taskTitleCtrl.dispose();
    _taskDescCtrl.dispose();
    _soulController.dispose();
    _modelCtrl.dispose();
    _fallbackModelCtrl.dispose();
    _maxTokensCtrl.dispose();
    _temperatureCtrl.dispose();
    _contextWindowCtrl.dispose();
    _maxToolRoundsCtrl.dispose();
    _dailyTokenCtrl.dispose();
    _monthlyTokenCtrl.dispose();
    _nameController.dispose();
    _channelTokenCtrl.dispose();
    _channelIdCtrl.dispose();
    _channelSecretCtrl.dispose();
    _channelEncryptKeyCtrl.dispose();
    _channelPublicKeyCtrl.dispose();
    _scheduleNameCtrl.dispose();
    _scheduleCronCtrl.dispose();
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
        _fetchPulseData();
        break;
      case 3:
        _fetchMindData();
        break;
      case 4:
        _fetchToolsData();
        break;
      case 5:
        _fetchSkillsData();
        break;
      case 6:
        _fetchRelationshipsData();
        break;
      case 7:
        _fetchWorkspaceFiles();
        break;
      case 8:
        _fetchActivity();
        break;
      case 9:
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
      final tasks = await _api.listTasks(
        widget.agentId,
        status: _taskFilter == 'all' ? null : _taskFilter,
      );
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

  Future<void> _fetchTaskLogs(String taskId) async {
    try {
      final logs = await _api.getTaskLogs(widget.agentId, taskId);
      if (mounted) setState(() => _taskLogs = logs);
    } catch (_) {}
  }

  Future<void> _fetchPulseData() async {
    setState(() => _loadingPulse = true);
    try {
      final results = await Future.wait([
        _api.listTriggers(widget.agentId).catchError((_) => <dynamic>[]),
        _api.readFile(widget.agentId, 'agenda.md').catchError((_) => <String, dynamic>{}),
        _api.readFile(widget.agentId, 'monologue.md').catchError((_) => <String, dynamic>{}),
        _api.readFile(widget.agentId, 'task_history.md').catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      setState(() {
        _triggers = results[0] as List<dynamic>;
        _agendaContent = (results[1] as Map<String, dynamic>)['content'] as String?;
        _monologueContent = (results[2] as Map<String, dynamic>)['content'] as String?;
        _taskHistoryContent = (results[3] as Map<String, dynamic>)['content'] as String?;
        _loadingPulse = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPulse = false);
    }
  }

  Future<void> _fetchMindData() async {
    setState(() => _loadingMind = true);
    try {
      final results = await Future.wait([
        _api.readFile(widget.agentId, 'soul.md').catchError((_) => <String, dynamic>{}),
        _api.listFiles(widget.agentId, path: 'memory').catchError((_) => <dynamic>[]),
        _api.readFile(widget.agentId, 'heartbeat.md').catchError((_) => <String, dynamic>{}),
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
      final results = await Future.wait([
        _api.listTools().catchError((_) => <dynamic>[]),
        _api.listAgentTools(widget.agentId).catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _platformTools = results[0];
        _agentTools = results[1];
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

  Future<void> _fetchRelationshipsData() async {
    setState(() => _loadingRelationships = true);
    try {
      final results = await Future.wait([
        _api.getRelationships(widget.agentId).catchError((_) => <dynamic>[]),
        _api.getAgentRelationships(widget.agentId).catchError((_) => <dynamic>[]),
        _api.listAgents().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _humanRelationships = results[0];
        _agentRelationships = results[1];
        _allAgentsList = results[2];
        _loadingRelationships = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRelationships = false);
      _showSnack('加载关系失败: ${_errMsg(e)}');
    }
  }

  Future<void> _deleteRelationship(String relId) async {
    try {
      await _api.deleteRelationship(widget.agentId, relId);
      _fetchRelationshipsData();
      _showSnack('已删除关系');
    } catch (e) {
      _showSnack('删除失败: ${_errMsg(e)}');
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
      ]);
      if (!mounted) return;
      final agent = _agent ?? {};
      setState(() {
        _llmModels = results[0] as List<dynamic>;
        _channelConfig = results[1] as Map<String, dynamic>?;
        _modelCtrl.text = (agent['primary_model_id'] ?? agent['model'] ?? '') as String;
        _fallbackModelCtrl.text = (agent['fallback_model_id'] ?? agent['fallback_model'] ?? '') as String;
        _maxTokensCtrl.text = (agent['max_tokens'] ?? 4096).toString();
        _temperatureCtrl.text = (agent['temperature'] ?? 0.7).toString();
        _contextWindowCtrl.text = (agent['context_window'] ?? 100).toString();
        _maxToolRoundsCtrl.text = (agent['max_tool_rounds'] ?? 50).toString();
        _dailyTokenCtrl.text = (agent['daily_token_limit'] ?? '').toString();
        _monthlyTokenCtrl.text = (agent['monthly_token_limit'] ?? '').toString();
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

  Future<void> _createTask() async {
    final title = _taskTitleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('请输入任务标题');
      return;
    }
    setState(() => _creatingTask = true);
    try {
      await _api.createTask(widget.agentId, {
        'title': title,
        'description': _taskDescCtrl.text.trim(),
        'priority': _taskPriority,
        'type': 'todo',
      });
      _taskTitleCtrl.clear();
      _taskDescCtrl.clear();
      if (!mounted) return;
      setState(() {
        _creatingTask = false;
        _showCreateTask = false;
        _taskPriority = 'medium';
      });
      _showSnack('任务已创建');
      _fetchTasks();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingTask = false);
      _showSnack('创建任务失败: ${_errMsg(e)}');
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
    try {
      await _api.toggleAgentTool(widget.agentId, toolId, enabled);
      _fetchToolsData();
    } catch (e) {
      _showSnack('工具开关失败: ${_errMsg(e)}');
    }
  }

  Widget _buildToolConfigFields(String toolId, Map<String, dynamic> schema) {
    final fields = (schema['fields'] as List?) ?? [];
    if (fields.isEmpty) return const SizedBox.shrink();
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
          _toolConfigControllers[ctrlKey] ??= TextEditingController(text: field['value']?.toString() ?? '');
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
    try {
      final res = await _api.readFile(widget.agentId, 'skills/$name');
      if (!mounted) return;
      setState(() {
        _viewingSkillContent = res['content'] as String?;
        _viewingSkillName = name;
      });
    } catch (e) {
      _showSnack('读取技能文件失败: ${_errMsg(e)}');
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

  Future<void> _deleteTrigger(String triggerId) async {
    final confirmed = await _showConfirmDialog(
      '删除触发器',
      '确认删除此触发器吗？',
    );
    if (confirmed != true) return;
    try {
      await _api.deleteTrigger(widget.agentId, triggerId);
      _showSnack('触发器已删除');
      _fetchPulseData();
    } catch (e) {
      _showSnack('删除触发器失败: ${_errMsg(e)}');
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

  Future<void> _toggleTrigger(String triggerId, bool enabled) async {
    try {
      await _api.updateTrigger(widget.agentId, triggerId, {'enabled': enabled});
      _fetchPulseData();
    } catch (e) {
      _showSnack('更新触发器失败: ${_errMsg(e)}');
    }
  }

  Future<void> _triggerTask(String taskId) async {
    try {
      await _api.triggerTask(widget.agentId, taskId);
      _showSnack('任务已触发');
      _fetchTasks();
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

  Future<void> _createSchedule() async {
    final name = _scheduleNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('请输入计划名称');
      return;
    }
    setState(() => _creatingSchedule = true);
    try {
      final data = <String, dynamic>{
        'name': name,
        'frequency': _scheduleFrequency,
      };
      if (_scheduleCronCtrl.text.trim().isNotEmpty) {
        data['cron'] = _scheduleCronCtrl.text.trim();
      }
      await _api.createSchedule(widget.agentId, data);
      _scheduleNameCtrl.clear();
      _scheduleCronCtrl.clear();
      if (!mounted) return;
      setState(() {
        _creatingSchedule = false;
        _showCreateSchedule = false;
        _scheduleFrequency = 'daily';
      });
      _showSnack('计划已创建');
      _fetchSchedules();
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingSchedule = false);
      _showSnack('创建计划失败: ${_errMsg(e)}');
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

  Future<void> _showAddHumanRelationship() async {
    final searchCtrl = TextEditingController();
    String relType = 'collaborator';
    final descCtrl = TextEditingController();
    List<dynamic> searchResults = [];
    Map<String, dynamic>? selectedMember;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('添加人类关系', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: '搜索成员', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                  onChanged: (val) async {
                    if (val.length < 2) return;
                    try {
                      final members = await _api.listOrgMembers(search: val);
                      setDialogState(() => searchResults = members);
                    } catch (_) {}
                  },
                ),
                if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView(
                      shrinkWrap: true,
                      children: searchResults.map((m) {
                        final member = m as Map<String, dynamic>;
                        final name = member['display_name'] as String? ?? member['username'] as String? ?? '';
                        final isSelected = selectedMember?['id'] == member['id'];
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          selectedTileColor: AppColors.accentPrimary.withValues(alpha: 0.1),
                          title: Text(name, style: const TextStyle(fontSize: 13)),
                          onTap: () => setDialogState(() { selectedMember = member; searchCtrl.text = name; searchResults = []; }),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relType,
                  decoration: const InputDecoration(labelText: '关系类型', isDense: true),
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'direct_leader', child: Text('直属上级')),
                    DropdownMenuItem(value: 'collaborator', child: Text('协作者')),
                    DropdownMenuItem(value: 'stakeholder', child: Text('利益相关者')),
                    DropdownMenuItem(value: 'team_member', child: Text('团队成员')),
                    DropdownMenuItem(value: 'subordinate', child: Text('下属')),
                    DropdownMenuItem(value: 'mentor', child: Text('导师')),
                    DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) { if (v != null) setDialogState(() => relType = v); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: '描述 (可选)', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: selectedMember == null ? null : () async {
                try {
                  await _api.updateRelationships(widget.agentId, [
                    ..._humanRelationships,
                    {
                      'user_id': selectedMember!['id'],
                      'relation_type': relType,
                      'description': descCtrl.text.trim(),
                    },
                  ]);
                  Navigator.pop(ctx);
                  _fetchRelationshipsData();
                  _showSnack('关系已添加');
                } catch (e) {
                  _showSnack('添加失败: ${_errMsg(e)}');
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    searchCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _showAddAgentRelationship() async {
    String? selectedAgentId;
    String relType = 'collaborator';
    final descCtrl = TextEditingController();
    // Filter out current agent
    final otherAgents = _allAgentsList.where((a) {
      final ag = a as Map<String, dynamic>;
      return ag['id']?.toString() != widget.agentId;
    }).toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('添加 Agent 关系', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedAgentId,
                  decoration: const InputDecoration(labelText: '选择 Agent', isDense: true),
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  isExpanded: true,
                  items: otherAgents.map((a) {
                    final ag = a as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: ag['id']?.toString(),
                      child: Text(ag['name'] as String? ?? '未知', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedAgentId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relType,
                  decoration: const InputDecoration(labelText: '关系类型', isDense: true),
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'peer', child: Text('同级')),
                    DropdownMenuItem(value: 'supervisor', child: Text('上级')),
                    DropdownMenuItem(value: 'assistant', child: Text('助手')),
                    DropdownMenuItem(value: 'collaborator', child: Text('协作者')),
                    DropdownMenuItem(value: 'other', child: Text('其他')),
                  ],
                  onChanged: (v) { if (v != null) setDialogState(() => relType = v); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(labelText: '描述 (可选)', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: selectedAgentId == null ? null : () async {
                try {
                  await _api.updateRelationships(widget.agentId, [
                    ..._agentRelationships,
                    {
                      'target_agent_id': selectedAgentId,
                      'relation_type': relType,
                      'description': descCtrl.text.trim(),
                    },
                  ]);
                  Navigator.pop(ctx);
                  _fetchRelationshipsData();
                  _showSnack('关系已添加');
                } catch (e) {
                  _showSnack('添加失败: ${_errMsg(e)}');
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
    descCtrl.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────


  static const _segmentLabelMap = {
    'all': '全部',
    'pending': '待处理',
    'running': '进行中',
    'completed': '已完成',
    'failed': '失败',
    'agenda': '日程',
    'triggers': '触发器',
    'monologue': '独白',
    'history': '历史',
    'user': '用户',
    'system': '系统',
    'error': '错误',
  };

  String _segmentLabel(String key) {
    return _segmentLabelMap[key] ?? (key[0].toUpperCase() + key.substring(1));
  }

  String _taskStatusLabel(String status) {
    switch (status) {
      case 'completed':
      case 'done':
        return '已完成';
      case 'running':
      case 'in_progress':
        return '进行中';
      case 'failed':
      case 'error':
        return '失败';
      case 'pending':
        return '待处理';
      default:
        return status;
    }
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
        final detail = data['detail'] as String?;
        if (detail != null && detail.isNotEmpty) return detail;
        final msg = data['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
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



  Color _priorityColor(String? p) {
    switch (p) {
      case 'high':
      case 'urgent':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textTertiary;
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
          _buildPulseTab(),
          _buildMindTab(),
          _buildToolsTab(),
          _buildSkillsTab(),
          _buildRelationshipsTab(),
          _buildWorkspaceTab(),
          _buildActivityTab(),
          _buildSettingsTab(agent),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 0 : Overview
  // ═══════════════════════════════════════════════════════════

  Widget _buildOverviewTab(Map<String, dynamic> agent) {
    final createdAt = agent['created_at'];
    final updatedAt = agent['updated_at'];
    final tokens = (_metrics?['tokens'] as Map<String, dynamic>?) ?? {};
    final tasks = (_metrics?['tasks'] as Map<String, dynamic>?) ?? {};
    final activity = (_metrics?['activity'] as Map<String, dynamic>?) ?? {};
    final tokensUsed = (tokens['used_month'] ?? 0) as num;
    final tokensLimit = (tokens['limit_month'] ?? 0) as num;
    final dailyTokens = (tokens['used_today'] ?? 0) as num;
    final dailyLimit = (tokens['limit_day'] ?? 0) as num;
    final tasksCompleted = (tasks['done'] ?? 0) as num;
    final tasksTotal = (tasks['total'] ?? 0) as num;
    final actionsLast24h = (activity['actions_last_24h'] ?? 0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metrics ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.analytics, label: '数据统计'),
                const SizedBox(height: 16),
                _tokenBar('月度 Token', tokensUsed.toDouble(), tokensLimit > 0 ? tokensLimit.toDouble() : 100000),
                const SizedBox(height: 12),
                if (dailyLimit > 0)
                  _tokenBar('每日 Token', dailyTokens.toDouble(), dailyLimit.toDouble()),
                if (dailyLimit > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricTile('总任务', tasksTotal.toString(), Icons.assignment)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile('已完成', tasksCompleted.toString(), Icons.check_circle)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile('24h操作', actionsLast24h.toString(), Icons.trending_up)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Recent Activity ──
          if (_recentActivity.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(icon: Icons.history, label: '近期活动'),
                  const SizedBox(height: 12),
                  ..._recentActivity.take(5).map((a) {
                    final act = a as Map<String, dynamic>;
                    final msg = act['summary'] as String? ?? act['message'] as String? ?? '';
                    final ts = act['created_at'] ?? act['timestamp'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(_fmtRelative(ts), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (_recentActivity.isNotEmpty) const SizedBox(height: 16),

          // ── Info ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.info_outline, label: '基本信息'),
                const SizedBox(height: 12),
                _infoRow('Agent ID', widget.agentId),
                _infoRow('创建时间', _fmtTs(createdAt)),
                _infoRow('更新时间', _fmtTs(updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenBar(String label, double used, double limit) {
    final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(
              '${used.toInt()} / ${limit.toInt()} ($pct%)',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation(
              ratio > 0.9
                  ? AppColors.error
                  : ratio > 0.7
                      ? AppColors.warning
                      : AppColors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1 : Tasks
  // ═══════════════════════════════════════════════════════════

  Widget _buildTasksTab() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.task_alt, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('任务', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _segmentedControl(
                options: const ['all', 'pending', 'running', 'completed', 'failed'],
                selected: _taskFilter,
                onChanged: (v) {
                  setState(() => _taskFilter = v);
                  _fetchTasks();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新建任务'),
                onPressed: () => setState(() => _showCreateTask = !_showCreateTask),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
                onPressed: _fetchTasks,
              ),
            ],
          ),
        ),

        // Create Form
        if (_showCreateTask)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('创建任务', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskTitleCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: '标题', hintText: '输入任务标题...'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _taskDescCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(labelText: '描述', hintText: '描述任务内容...'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _taskPriority,
                    decoration: const InputDecoration(labelText: '优先级'),
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('低')),
                      DropdownMenuItem(value: 'medium', child: Text('中')),
                      DropdownMenuItem(value: 'high', child: Text('高')),
                      DropdownMenuItem(value: 'urgent', child: Text('紧急')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _taskPriority = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showCreateTask = false),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _creatingTask ? null : _createTask,
                        child: _creatingTask ? _miniSpinner() : const Text('创建'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Schedules section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('计划任务', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('新建', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _showCreateSchedule = !_showCreateSchedule),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  ),
                ],
              ),
              if (_showCreateSchedule) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('创建计划', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _scheduleNameCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        decoration: const InputDecoration(labelText: '名称', hintText: '计划名称', isDense: true),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _scheduleFrequency,
                        decoration: const InputDecoration(labelText: '频率', isDense: true),
                        dropdownColor: AppColors.bgElevated,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'minutely', child: Text('每分钟')),
                          DropdownMenuItem(value: 'hourly', child: Text('每小时')),
                          DropdownMenuItem(value: 'daily', child: Text('每天')),
                          DropdownMenuItem(value: 'weekly', child: Text('每周')),
                          DropdownMenuItem(value: 'monthly', child: Text('每月')),
                          DropdownMenuItem(value: 'custom', child: Text('自定义 Cron')),
                        ],
                        onChanged: (v) { if (v != null) setState(() => _scheduleFrequency = v); },
                      ),
                      if (_scheduleFrequency == 'custom') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _scheduleCronCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                          decoration: const InputDecoration(labelText: 'Cron 表达式', hintText: '* * * * *', isDense: true),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => setState(() => _showCreateSchedule = false), child: const Text('取消')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _creatingSchedule ? null : _createSchedule,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), textStyle: const TextStyle(fontSize: 12)),
                            child: _creatingSchedule ? _miniSpinner() : const Text('创建'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (_schedules.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._schedules.map((s) {
                  final sched = s as Map<String, dynamic>;
                  final name = sched['name'] as String? ?? sched['cron'] as String? ?? '计划';
                  final id = sched['id']?.toString() ?? '';
                  final enabled = sched['enabled'] == true || sched['is_active'] == true;
                  final nextFire = sched['next_fire_time'] ?? sched['next_run_at'];
                  final fireCount = sched['fire_count'] ?? sched['run_count'] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: enabled ? AppColors.accentPrimary : AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                              if (nextFire != null)
                                Text('下次: ${_fmtRelative(nextFire)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                              if (fireCount > 0)
                                Text('已执行 $fireCount 次', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline, size: 16, color: AppColors.accentPrimary),
                          tooltip: '立即触发',
                          onPressed: () => _triggerSchedule(id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                          tooltip: '删除',
                          onPressed: () => _deleteSchedule(id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Task List
        Expanded(
          child: _loadingTasks
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _tasks.isEmpty
                  ? _emptyState('暂无任务', '创建一个任务开始吧。')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _tasks.length,
                      itemBuilder: (ctx, i) {
                        final task = _tasks[i] as Map<String, dynamic>;
                        return _buildTaskItem(task);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? '无标题';
    final desc = task['description'] as String? ?? '';
    final status = task['status'] as String? ?? 'pending';
    final priority = task['priority'] as String? ?? 'medium';
    final createdAt = task['created_at'];
    final taskId = task['id']?.toString() ?? '';
    final isExpanded = _selectedTaskId == taskId;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTaskId == taskId) {
            _selectedTaskId = null;
            _taskLogs = [];
          } else {
            _selectedTaskId = taskId;
            _fetchTaskLogs(taskId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpanded ? AppColors.accentPrimary.withValues(alpha: 0.4) : AppColors.borderSubtle,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _priorityColor(priority), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                _taskStatusChip(status),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '优先级: ${priority[0].toUpperCase()}${priority.substring(1)}',
                  style: TextStyle(color: _priorityColor(priority), fontSize: 11),
                ),
                const Spacer(),
                if (status == 'pending')
                  GestureDetector(
                    onTap: () => _triggerTask(taskId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 11, color: AppColors.accentPrimary),
                          SizedBox(width: 3),
                          Text('触发', style: TextStyle(color: AppColors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                Text(_fmtTs(createdAt), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
            // Expanded task logs
            if (isExpanded && _taskLogs.isNotEmpty) ...[
              const Divider(height: 16, color: AppColors.borderSubtle),
              const Text('任务日志', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._taskLogs.take(10).map((l) {
                final log = l as Map<String, dynamic>;
                final logMsg = log['message'] as String? ?? log['content'] as String? ?? '';
                final logTs = log['timestamp'] ?? log['created_at'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chevron_right, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(logMsg, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      Text(_fmtRelative(logTs), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _taskStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'completed':
      case 'done':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'running':
      case 'in_progress':
        bg = AppColors.accentPrimary.withValues(alpha: 0.15);
        fg = AppColors.accentPrimary;
        break;
      case 'failed':
      case 'error':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.textTertiary.withValues(alpha: 0.15);
        fg = AppColors.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(_taskStatusLabel(status), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3 : Pulse
  // ═══════════════════════════════════════════════════════════

  Widget _buildPulseTab() {
    if (_loadingPulse) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _segmentedControl(
                  options: const ['agenda', 'triggers', 'monologue', 'history'],
                  selected: _pulseSection,
                  onChanged: (v) => setState(() => _pulseSection = v),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
                onPressed: _fetchPulseData,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildPulseSection()),
      ],
    );
  }

  Widget _buildPulseSection() {
    switch (_pulseSection) {
      case 'agenda':
        return _buildPulseContent(
          icon: Icons.calendar_today,
          iconColor: AppColors.accentPrimary,
          title: '日程',
          content: _agendaContent,
          emptyMsg: '未找到日程文件。',
        );
      case 'triggers':
        return _buildTriggersSection();
      case 'monologue':
        return _buildPulseContent(
          icon: Icons.psychology,
          iconColor: AppColors.accentPrimary,
          title: '内心独白',
          content: _monologueContent,
          emptyMsg: '暂无内心独白内容。',
        );
      case 'history':
        return _buildPulseContent(
          icon: Icons.history,
          iconColor: AppColors.warning,
          title: '任务历史',
          content: _taskHistoryContent,
          emptyMsg: '暂无任务历史。',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPulseContent({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? content,
    required String emptyMsg,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTriggersSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: AppColors.warning, size: 18),
                SizedBox(width: 8),
                Text('触发器', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_triggers.isEmpty)
              const Text(
                '暂无触发器配置。',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic),
              )
            else
              ..._triggers.map((t) {
                final trigger = t as Map<String, dynamic>;
                final id = trigger['id']?.toString() ?? '';
                final type = trigger['type'] as String? ?? 'unknown';
                final description = trigger['description'] as String? ?? '';
                final enabled = trigger['enabled'] == true;
                final cron = trigger['cron'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        enabled ? Icons.check_circle : Icons.cancel,
                        color: enabled ? AppColors.success : AppColors.textTertiary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            if (description.isNotEmpty)
                              Text(description, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (cron.isNotEmpty)
                              Text('cron: $cron', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontFamily: 'monospace')),
                          ],
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (v) => _toggleTrigger(id, v),
                        activeColor: AppColors.accentPrimary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        onPressed: () => _deleteTrigger(id),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4 : Mind
  // ═══════════════════════════════════════════════════════════

  Widget _buildMindTab() {
    if (_loadingMind) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soul.md
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accentPrimary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('soul.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    if (!_editingSoul)
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                        onPressed: () => setState(() => _editingSoul = true),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
                      onPressed: _fetchMindData,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_editingSoul) ...[
                  TextField(
                    controller: _soulController,
                    maxLines: 15,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '定义 Agent 的性格和核心行为...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _soulController.text = _soulContent ?? '';
                          setState(() => _editingSoul = false);
                        },
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _savingSoul ? null : _saveSoulMd,
                        child: _savingSoul ? _miniSpinner() : const Text('保存'),
                      ),
                    ],
                  ),
                ] else
                  _codeBlock(_soulContent, '未找到 soul.md 文件，点击编辑按钮创建。'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Heartbeat (file only — settings controls are in Settings tab)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.favorite_outline, label: '心跳指令'),
                const SizedBox(height: 12),
                const Text('heartbeat.md', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                _codeBlock(_heartbeatContent, '未找到 heartbeat.md 文件。'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Memory Files
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.memory, label: '记忆文件'),
                const SizedBox(height: 12),
                if (_memoryFiles.isEmpty)
                  const Text(
                    '暂无记忆文件。',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic),
                  )
                else
                  ..._memoryFiles.map((f) {
                    final file = f as Map<String, dynamic>;
                    final name = file['name'] as String? ?? '';
                    final size = file['size'] ?? 0;
                    final modified = file['modified'] ?? file['updated_at'];
                    return InkWell(
                      onTap: () => _readMemoryFile(name),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, color: AppColors.textTertiary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                            if (modified != null)
                              Text(_fmtRelative(modified), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            const SizedBox(width: 8),
                            Text('$size 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 5 : Tools
  // ═══════════════════════════════════════════════════════════

  Widget _buildToolsTab() {
    if (_loadingTools) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    final agentToolMap = <String, bool>{};
    for (final at in _agentTools) {
      final m = at as Map<String, dynamic>;
      final id = m['tool_id']?.toString() ?? m['id']?.toString() ?? '';
      agentToolMap[id] = m['enabled'] == true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.build, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('工具', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18), onPressed: _fetchToolsData),
            ],
          ),
          const SizedBox(height: 12),

          // Platform Tools
          if (_platformTools.isNotEmpty) ...[
            const Text('平台工具', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._platformTools.map((t) {
              final tool = t as Map<String, dynamic>;
              final id = tool['id']?.toString() ?? '';
              final name = tool['name'] as String? ?? '未知';
              final description = tool['description'] as String? ?? '';
              final category = tool['category'] as String? ?? '';
              final enabled = agentToolMap[id] ?? false;
              final configSchema = tool['config_schema'] as Map<String, dynamic>?;
              final hasConfig = configSchema != null && (configSchema['fields'] as List?)?.isNotEmpty == true;
              final isExpanded = _expandedToolId == id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                  ),
                                  if (category.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgTertiary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                                    ),
                                  ],
                                ],
                              ),
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(description, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ),
                        if (hasConfig)
                          IconButton(
                            icon: Icon(isExpanded ? Icons.expand_less : Icons.settings, color: AppColors.textSecondary, size: 18),
                            onPressed: () => setState(() => _expandedToolId = isExpanded ? null : id),
                          ),
                        Switch(
                          value: enabled,
                          onChanged: (v) => _toggleTool(id, v),
                          activeColor: AppColors.accentPrimary,
                        ),
                      ],
                    ),
                    if (isExpanded && hasConfig) ...[
                      const Divider(height: 16),
                      _buildToolConfigFields(id, configSchema),
                    ],
                  ],
                ),
              );
            }),
          ],

          if (_platformTools.isEmpty && _agentTools.isEmpty)
            _emptyState('暂无工具', '未找到平台工具或 Agent 安装的工具。'),

          // Agent-installed Tools
          if (_agentTools.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Agent 安装的工具', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._agentTools.map((t) {
              final tool = t as Map<String, dynamic>;
              final name = tool['name'] as String? ?? tool['tool_id']?.toString() ?? '未知';
              final enabled = tool['enabled'] == true;
              final toolId = tool['tool_id']?.toString() ?? tool['id']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      enabled ? Icons.check_circle : Icons.cancel,
                      color: enabled ? AppColors.success : AppColors.textTertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                    Switch(
                      value: enabled,
                      onChanged: (v) => _toggleTool(toolId, v),
                      activeColor: AppColors.accentPrimary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 6 : Skills
  // ═══════════════════════════════════════════════════════════

  Widget _buildSkillsTab() {
    if (_loadingSkills) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    // Viewing a skill file
    if (_viewingSkillContent != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() {
                    _viewingSkillContent = null;
                    _viewingSkillName = null;
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _viewingSkillName ?? '技能',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                  tooltip: '编辑',
                  onPressed: _editSkillFile,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: SelectableText(
                  _viewingSkillContent ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Skill list
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('技能', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18), onPressed: _fetchSkillsData),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.accentPrimary, size: 18),
                tooltip: '新建技能',
                onPressed: _createSkillFile,
              ),
              IconButton(
                icon: const Icon(Icons.download, color: AppColors.accentPrimary, size: 18),
                tooltip: '导入预设技能',
                onPressed: () async {
                  await _fetchSkillPresets();
                  if (!mounted) return;
                  setState(() => _showSkillPresets = !_showSkillPresets);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Skill presets panel
        if (_showSkillPresets && _skillPresets.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('预设技能', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillPresets.map((s) {
                    final skill = s as Map<String, dynamic>;
                    final id = skill['id']?.toString() ?? '';
                    final name = skill['name'] as String? ?? '未知';
                    return ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _importSkillPreset(id),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _skillFiles.isEmpty
              ? _emptyState('暂无技能', '该 Agent 未找到技能文件。')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _skillFiles.length,
                  itemBuilder: (ctx, i) {
                    final file = _skillFiles[i] as Map<String, dynamic>;
                    final name = file['name'] as String? ?? '';
                    final size = file['size'] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.code, color: AppColors.accentPrimary, size: 20),
                        title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        subtitle: Text('$size 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: AppColors.textSecondary, size: 18),
                              onPressed: () => _openSkillFile(file),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              onPressed: () => _deleteSkillFile(name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 7 : Relationships
  // ═══════════════════════════════════════════════════════════

  Widget _buildRelationshipsTab() {
    if (_loadingRelationships) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('关系', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18), onPressed: _fetchRelationshipsData),
            ],
          ),
          const SizedBox(height: 16),

          // Human relationships
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.person, label: '人类关系'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('添加', style: TextStyle(fontSize: 12)),
                    onPressed: _showAddHumanRelationship,
                  ),
                ),
                const SizedBox(height: 4),
                if (_humanRelationships.isEmpty)
                  const Text('暂无人类关系配置。', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic))
                else
                  ..._humanRelationships.map((r) {
                    final rel = r as Map<String, dynamic>;
                    final id = rel['id']?.toString() ?? '';
                    final name = rel['user_name'] as String? ?? rel['name'] as String? ?? '未知';
                    final type = rel['relation_type'] as String? ?? '';
                    final desc = rel['description'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: AppColors.accentPrimary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                if (type.isNotEmpty)
                                  Text(_relationTypeLabel(type), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                if (desc.isNotEmpty)
                                  Text(desc, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            onPressed: () => _deleteRelationship(id),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Agent relationships
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.smart_toy, label: 'Agent 关系'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('添加', style: TextStyle(fontSize: 12)),
                    onPressed: _showAddAgentRelationship,
                  ),
                ),
                const SizedBox(height: 4),
                if (_agentRelationships.isEmpty)
                  const Text('暂无 Agent 关系配置。', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic))
                else
                  ..._agentRelationships.map((r) {
                    final rel = r as Map<String, dynamic>;
                    final id = rel['id']?.toString() ?? '';
                    final name = rel['target_agent_name'] as String? ?? rel['name'] as String? ?? '未知';
                    final type = rel['relation_type'] as String? ?? '';
                    final desc = rel['description'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                                if (type.isNotEmpty)
                                  Text(_agentRelationTypeLabel(type), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                if (desc.isNotEmpty)
                                  Text(desc, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            onPressed: () => _deleteRelationship(id),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relationTypeLabel(String type) {
    const labels = {
      'direct_leader': '直属上级',
      'collaborator': '协作者',
      'stakeholder': '利益相关者',
      'team_member': '团队成员',
      'subordinate': '下属',
      'mentor': '导师',
      'other': '其他',
    };
    return labels[type] ?? type;
  }

  String _agentRelationTypeLabel(String type) {
    const labels = {
      'peer': '同级',
      'supervisor': '上级',
      'assistant': '助手',
      'collaborator': '协作者',
      'other': '其他',
    };
    return labels[type] ?? type;
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 8 : Workspace (file browser)
  // ═══════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════
  // TAB 8 : Workspace (file browser)
  // ═══════════════════════════════════════════════════════════

  Widget _buildWorkspaceTab() {
    // Viewing a file
    if (_viewingFileContent != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() {
                    _viewingFileContent = null;
                    _viewingFileName = null;
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _viewingFileName ?? '文件',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                  tooltip: '编辑',
                  onPressed: _editWorkspaceFile,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: SelectableText(
                  _viewingFileContent ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Breadcrumb
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              if (_currentPath.isNotEmpty) ...[
                InkWell(
                  onTap: () => _fetchWorkspaceFiles(),
                  child: const Text('根目录', style: TextStyle(color: AppColors.accentPrimary, fontSize: 13, decoration: TextDecoration.underline)),
                ),
                const Text(' / ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ..._buildBreadcrumbs(),
              ],
              if (_currentPath.isEmpty)
                const Text('工作区 (根目录)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_currentPath.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: AppColors.textSecondary, size: 18),
                  tooltip: '返回上级',
                  onPressed: () {
                    final parts = _currentPath.split('/');
                    parts.removeLast();
                    _fetchWorkspaceFiles(parts.join('/'));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.create_new_folder, color: AppColors.textSecondary, size: 18),
                tooltip: '新建文件夹',
                onPressed: _createWorkspaceFolder,
              ),
              IconButton(
                icon: const Icon(Icons.note_add, color: AppColors.textSecondary, size: 18),
                tooltip: '新建文件',
                onPressed: _createWorkspaceFile,
              ),
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.textSecondary, size: 18),
                tooltip: '上传文件',
                onPressed: _uploadWorkspaceFile,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
                onPressed: () => _fetchWorkspaceFiles(_currentPath),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // File List
        Expanded(
          child: _loadingWorkspace
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _workspaceFiles.isEmpty
                  ? _emptyState('空目录', '该目录下没有文件。')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _workspaceFiles.length,
                      itemBuilder: (ctx, i) {
                        final file = _workspaceFiles[i] as Map<String, dynamic>;
                        final name = file['name'] as String? ?? '';
                        final isDir = file['is_directory'] == true || file['type'] == 'directory';
                        final size = file['size'] ?? 0;
                        final modified = file['modified'] ?? file['updated_at'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isDir ? Icons.folder : _fileIcon(name),
                              color: isDir ? AppColors.warning : AppColors.textTertiary,
                              size: 20,
                            ),
                            title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            subtitle: isDir
                                ? null
                                : Row(
                                    children: [
                                      Text('$size 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                      if (modified != null) ...[
                                        const SizedBox(width: 12),
                                        Text(_fmtRelative(modified), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                            trailing: isDir
                                ? const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18)
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    onPressed: () => _deleteWorkspaceFile(name),
                                  ),
                            onTap: () => _openWorkspaceFile(file),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'py':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'md':
        return Icons.article;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'txt':
        return Icons.text_snippet;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  List<Widget> _buildBreadcrumbs() {
    final parts = _currentPath.split('/');
    final widgets = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      final isLast = i == parts.length - 1;
      final pathUpTo = parts.sublist(0, i + 1).join('/');
      if (isLast) {
        widgets.add(Text(parts[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)));
      } else {
        widgets.add(InkWell(
          onTap: () => _fetchWorkspaceFiles(pathUpTo),
          child: Text(parts[i], style: const TextStyle(color: AppColors.accentPrimary, fontSize: 13, decoration: TextDecoration.underline)),
        ));
        widgets.add(const Text(' / ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)));
      }
    }
    return widgets;
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 8 : Activity Log
  // ═══════════════════════════════════════════════════════════

  Widget _buildActivityTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.history, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('活动日志', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _segmentedControl(
                options: const ['all', 'user', 'system', 'error'],
                selected: _logFilter,
                onChanged: (v) {
                  setState(() => _logFilter = v);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
                onPressed: _fetchActivity,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingActivity
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _filteredActivities.isEmpty
                  ? _emptyState('暂无活动', '该 Agent 尚未记录任何活动。')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (ctx, i) {
                        final act = _filteredActivities[i] as Map<String, dynamic>;
                        return _buildActivityItem(act);
                      },
                    ),
        ),
      ],
    );
  }

  List<dynamic> get _filteredActivities {
    if (_logFilter == 'all') return _activities;
    return _activities.where((a) {
      final act = a as Map<String, dynamic>;
      final type = act['action_type'] as String? ?? act['type'] as String? ?? '';
      switch (_logFilter) {
        case 'error':
          return type == 'error' || type == 'task_failed';
        case 'user':
          return type == 'chat_reply' || type == 'chat' || type == 'message'
              || type == 'web_msg_sent' || type == 'agent_msg_sent' || type == 'feishu_msg_sent'
              || type == 'task_created' || type == 'task_updated' || type == 'task_complete' || type == 'task_completed';
        case 'system':
          return type == 'heartbeat' || type == 'schedule_run' || type == 'tool_call'
              || type == 'file_written' || type == 'plaza_post'
              || type == 'start' || type == 'started' || type == 'stop' || type == 'stopped';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildActivityItem(Map<String, dynamic> act) {
    final type = act['action_type'] as String? ?? act['type'] as String? ?? 'event';
    final message = act['summary'] as String? ?? act['message'] as String? ?? '';
    final timestamp = act['created_at'] ?? act['timestamp'];
    final detailRaw = act['detail'] ?? act['details'];
    final details = detailRaw is String ? detailRaw : (detailRaw != null ? detailRaw.toString() : '');
    final actId = act['id']?.toString() ?? '';
    final isExpanded = _expandedLogId == actId;

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'task_created':
      case 'task_updated':
      case 'task_complete':
      case 'task_completed':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'error':
      case 'task_failed':
        icon = Icons.error;
        iconColor = AppColors.error;
        break;
      case 'chat_reply':
      case 'web_msg_sent':
      case 'agent_msg_sent':
      case 'feishu_msg_sent':
      case 'chat':
      case 'message':
        icon = Icons.chat_bubble;
        iconColor = AppColors.accentPrimary;
        break;
      case 'heartbeat':
        icon = Icons.favorite;
        iconColor = AppColors.warning;
        break;
      case 'schedule_run':
        icon = Icons.schedule;
        iconColor = AppColors.textSecondary;
        break;
      case 'file_written':
        icon = Icons.insert_drive_file;
        iconColor = AppColors.accentPrimary;
        break;
      case 'plaza_post':
        icon = Icons.forum;
        iconColor = AppColors.accentPrimary;
        break;
      case 'start':
      case 'started':
        icon = Icons.play_circle;
        iconColor = AppColors.success;
        break;
      case 'stop':
      case 'stopped':
        icon = Icons.stop_circle;
        iconColor = AppColors.warning;
        break;
      case 'tool_call':
        icon = Icons.build;
        iconColor = AppColors.accentPrimary;
        break;
      default:
        icon = Icons.circle;
        iconColor = AppColors.textTertiary;
    }

    return GestureDetector(
      onTap: details.isNotEmpty
          ? () => setState(() => _expandedLogId = isExpanded ? null : actId)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(_activityTypeLabel(type), style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(_fmtTs(timestamp), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                  if (isExpanded && details.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(6)),
                      child: SelectableText(
                        details,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activityTypeLabel(String type) {
    switch (type) {
      case 'chat_reply': return '聊天回复';
      case 'web_msg_sent': return '网页消息';
      case 'agent_msg_sent': return 'Agent 消息';
      case 'feishu_msg_sent': return '飞书消息';
      case 'tool_call': return '工具调用';
      case 'task_created': return '任务创建';
      case 'task_updated': return '任务更新';
      case 'task_complete': case 'task_completed': return '任务完成';
      case 'task_failed': return '任务失败';
      case 'error': return '错误';
      case 'heartbeat': return '心跳';
      case 'schedule_run': return '定时任务';
      case 'file_written': return '文件写入';
      case 'plaza_post': return '广场动态';
      case 'start': case 'started': return '启动';
      case 'stop': case 'stopped': return '停止';
      default: return type;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 9 : Settings
  // ═══════════════════════════════════════════════════════════

  Widget _buildSettingsTab(Map<String, dynamic> agent) {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Model Configuration ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.settings, label: '模型配置'),
                const SizedBox(height: 16),
                _buildModelDropdown('主模型', _modelCtrl),
                const SizedBox(height: 12),
                _buildModelDropdown('备用模型', _fallbackModelCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxTokensCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Token 上限', hintText: '4096'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _temperatureCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '温度', hintText: '0.7'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contextWindowCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '上下文窗口', hintText: '100'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxToolRoundsCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '最大工具轮次', hintText: '50'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Token 限额', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dailyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '每日 Token 限额', hintText: '不限'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _monthlyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '每月 Token 限额', hintText: '不限'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingSettings ? null : _saveSettings,
                    child: _savingSettings ? _miniSpinner() : const Text('保存设置'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Autonomy Policy ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.security, label: '自主权限策略'),
                const SizedBox(height: 4),
                const Text('控制 Agent 执行操作时的审批级别', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                const SizedBox(height: 12),
                ..._buildAutonomyPolicyRows(agent),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Heartbeat (Settings) ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('心跳', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('定时巡检广场、执行工作，会消耗 Token', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch(
                      value: agent['heartbeat_enabled'] == true,
                      activeColor: AppColors.accentPrimary,
                      onChanged: (v) async {
                        await _api.updateAgent(widget.agentId, {'heartbeat_enabled': v});
                        _fetchAgentSilent();
                      },
                    ),
                  ],
                ),
                if (agent['heartbeat_enabled'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('间隔', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(
                            text: '${agent['heartbeat_interval_minutes'] ?? 120}',
                          ),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onSubmitted: (val) async {
                            final v = int.tryParse(val) ?? 120;
                            final clamped = v < 1 ? 1 : v;
                            await _api.updateAgent(widget.agentId, {'heartbeat_interval_minutes': clamped});
                            _fetchAgentSilent();
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('分钟', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('活跃时段', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: TextEditingController(
                            text: agent['heartbeat_active_hours'] as String? ?? '09:00-18:00',
                          ),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: '09:00-18:00',
                            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                          onSubmitted: (val) async {
                            await _api.updateAgent(widget.agentId, {'heartbeat_active_hours': val.trim()});
                            _fetchAgentSilent();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (agent['last_heartbeat_at'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '上次心跳: ${_formatDateTime(agent['last_heartbeat_at'] as String)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Access Permissions ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.lock_outline, label: '访问权限'),
                const SizedBox(height: 12),
                const Text('作用范围', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _radioOption('company', '公司', agent['scope_type'] as String? ?? 'company', (v) async {
                      await _api.updateAgent(widget.agentId, {'scope_type': v});
                      _fetchAgentSilent();
                    }),
                    const SizedBox(width: 16),
                    _radioOption('user', '个人', agent['scope_type'] as String? ?? 'company', (v) async {
                      await _api.updateAgent(widget.agentId, {'scope_type': v});
                      _fetchAgentSilent();
                    }),
                  ],
                ),
                if ((agent['scope_type'] as String? ?? 'company') == 'company') ...[
                  const SizedBox(height: 16),
                  const Text('访问级别', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _radioOption('use', '使用', agent['access_level'] as String? ?? 'manage', (v) async {
                        await _api.updateAgent(widget.agentId, {'access_level': v});
                        _fetchAgentSilent();
                      }),
                      const SizedBox(width: 16),
                      _radioOption('manage', '管理', agent['access_level'] as String? ?? 'manage', (v) async {
                        await _api.updateAgent(widget.agentId, {'access_level': v});
                        _fetchAgentSilent();
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Channel Configuration ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_tethering, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('通道配置', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18), onPressed: _fetchSettingsData),
                  ],
                ),
                const SizedBox(height: 12),
                if (_channelConfig == null && !_showCreateChannel) ...[
                  const Text('未配置通道。', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('配置通道'),
                    onPressed: () => setState(() => _showCreateChannel = true),
                    style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
                  ),
                ] else if (_showCreateChannel) ...[
                  DropdownButtonFormField<String>(
                    value: _newChannelType,
                    decoration: const InputDecoration(labelText: '通道类型', isDense: true),
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'feishu', child: Text('飞书')),
                      DropdownMenuItem(value: 'slack', child: Text('Slack')),
                      DropdownMenuItem(value: 'discord', child: Text('Discord')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _newChannelType = v); },
                  ),
                  const SizedBox(height: 8),
                  if (_newChannelType == 'feishu') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'App ID', isDense: true, hintText: 'cli_xxx...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'App Secret', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelEncryptKeyCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Encrypt Key (可选)', isDense: true),
                    ),
                  ] else if (_newChannelType == 'slack') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true, hintText: 'xoxb-...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Signing Secret', isDense: true),
                    ),
                  ] else if (_newChannelType == 'discord') ...[
                    TextField(
                      controller: _channelIdCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Application ID', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelPublicKeyCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Public Key', isDense: true),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => setState(() => _showCreateChannel = false), child: const Text('取消')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _createChannel, child: const Text('保存')),
                    ],
                  ),
                ] else ...[
                  _settingRow('类型', _channelConfig?['type']?.toString() ?? '-'),
                  _settingRow('状态', _channelConfig?['status']?.toString() ?? '-'),
                  _settingRow('Webhook URL', _channelConfig?['webhook_url']?.toString() ?? '-'),
                  if (_channelConfig?['bot_name'] != null)
                    _settingRow('机器人名称', _channelConfig?['bot_name']?.toString() ?? '-'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('编辑'),
                        onPressed: () => setState(() => _showCreateChannel = true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('删除通道', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                        onPressed: _deleteChannel,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Danger Zone ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('危险操作', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agent 一旦删除将无法恢复，请谨慎操作。',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (!_showDeleteConfirm)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('删除智能体'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    onPressed: () => setState(() => _showDeleteConfirm = true),
                  )
                else
                  Row(
                    children: [
                      const Text('确定要删除吗？', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                        onPressed: _deleteAgent,
                        child: const Text('确认删除'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _showDeleteConfirm = false),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModelDropdown(String label, TextEditingController ctrl) {
    if (_llmModels.isNotEmpty) {
      final currentValue = ctrl.text;
      final hasMatch = _llmModels.any((m) {
        final model = m as Map<String, dynamic>;
        return model['id']?.toString() == currentValue;
      });
      return DropdownButtonFormField<String>(
        value: hasMatch ? currentValue : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        dropdownColor: AppColors.bgElevated,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        hint: Text('未选择', style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        items: [
          const DropdownMenuItem(value: '', child: Text('不使用', style: TextStyle(color: AppColors.textTertiary))),
          ..._llmModels.map((m) {
            final model = m as Map<String, dynamic>;
            final id = model['id']?.toString() ?? '';
            final displayLabel = (model['label'] as String?)?.isNotEmpty == true
                ? model['label'] as String
                : model['model']?.toString() ?? id;
            final provider = model['provider']?.toString() ?? '';
            final modelName = model['model']?.toString() ?? '';
            final subtitle = provider.isNotEmpty ? ' ($provider/$modelName)' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$displayLabel$subtitle',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (v) => setState(() => ctrl.text = v ?? ''),
      );
    }
    // No models configured yet — show hint to go to enterprise settings
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(labelText: label, hintText: '请先在企业设置中配置模型'),
        ),
        const SizedBox(height: 4),
        const Text('提示：请先前往「企业设置 → 模型池」添加 LLM 模型',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _settingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(child: SelectableText(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
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

// ── Reusable section header ────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
