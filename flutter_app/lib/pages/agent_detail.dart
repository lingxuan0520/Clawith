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
  final _roleController = TextEditingController();
  bool _editingRole = false;
  bool _savingRole = false;
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

  // ── Schedule creation ────────────────────────────────────
  bool _showCreateSchedule = false;
  final _scheduleNameCtrl = TextEditingController();
  final _scheduleCronCtrl = TextEditingController();
  String _scheduleFrequency = 'daily';
  bool _creatingSchedule = false;

  static const _tabLabels = [
    '状态',
    '聊天',
    '任务',
    '动态',
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
    _tabController.dispose();
    _roleController.dispose();
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
    _scheduleNameCtrl.dispose();
    _scheduleCronCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final idx = _tabController.index;
    // Chat tab -> navigate to separate chat page
    if (idx == 1) {
      _tabController.animateTo(0);
      context.push('/agents/${widget.agentId}/chat');
      return;
    }
    _loadTabData(idx);
  }

  void _loadTabData(int idx) {
    switch (idx) {
      case 0:
        _fetchOverviewData();
        break;
      case 2:
        _fetchTasks();
        _fetchSchedules();
        break;
      case 3:
        _fetchPulseData();
        break;
      case 4:
        _fetchMindData();
        break;
      case 5:
        _fetchToolsData();
        break;
      case 6:
        _fetchSkillsData();
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
        _roleController.text = agent['role_description'] as String? ?? '';
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

  Future<void> _startAgent() async {
    try {
      await _api.startAgent(widget.agentId);
      await _fetchAgent();
      _showSnack('智能体已启动');
    } catch (e) {
      _showSnack('启动失败: ${_errMsg(e)}');
    }
  }

  Future<void> _stopAgent() async {
    try {
      await _api.stopAgent(widget.agentId);
      await _fetchAgent();
      _showSnack('智能体已停止');
    } catch (e) {
      _showSnack('停止失败: ${_errMsg(e)}');
    }
  }

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

  Future<void> _saveRoleDescription() async {
    setState(() => _savingRole = true);
    try {
      await _api.updateAgent(widget.agentId, {
        'role_description': _roleController.text,
      });
      await _fetchAgentSilent();
      if (!mounted) return;
      setState(() {
        _editingRole = false;
        _savingRole = false;
      });
      _showSnack('角色描述已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingRole = false);
      _showSnack('保存失败: ${_errMsg(e)}');
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
      _showContentDialog(name, res['content'] as String? ?? '(empty)');
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
    _showSnack('请使用 Web 版本上传文件');
  }

  void _showExpiryEditor() {
    final agent = _agent;
    if (agent == null) return;
    final currentExpiry = agent['expires_at'] as String?;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('设置过期时间', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentExpiry != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('当前过期: ${_fmtTs(currentExpiry)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            const Text('快速续期', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _expiryBtn(ctx, '+24h', const Duration(hours: 24)),
                _expiryBtn(ctx, '+7d', const Duration(days: 7)),
                _expiryBtn(ctx, '+30d', const Duration(days: 30)),
                _expiryBtn(ctx, '+90d', const Duration(days: 90)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.all_inclusive, size: 16),
              label: const Text('永不过期'),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.updateAgent(widget.agentId, {'expires_at': null});
                  await _fetchAgentSilent();
                  _showSnack('已设置为永不过期');
                } catch (e) {
                  _showSnack('设置失败: ${_errMsg(e)}');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  Widget _expiryBtn(BuildContext ctx, String label, Duration duration) {
    return OutlinedButton(
      onPressed: () async {
        Navigator.pop(ctx);
        final newExpiry = DateTime.now().add(duration).toUtc().toIso8601String();
        try {
          await _api.updateAgent(widget.agentId, {'expires_at': newExpiry});
          await _fetchAgentSilent();
          _showSnack('过期时间已更新');
        } catch (e) {
          _showSnack('设置失败: ${_errMsg(e)}');
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: const BorderSide(color: AppColors.accentPrimary),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

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

  String _statusLabel(String? status) {
    switch (status) {
      case 'running':
        return '运行中';
      case 'idle':
        return '待机';
      case 'stopped':
        return '已停止';
      case 'error':
        return '错误';
      default:
        return status ?? '未知';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'running':
        return AppColors.statusRunning;
      case 'idle':
        return AppColors.statusIdle;
      case 'stopped':
        return AppColors.statusStopped;
      case 'error':
        return AppColors.statusError;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'running':
        return Icons.play_circle_filled;
      case 'idle':
        return Icons.pause_circle_filled;
      case 'stopped':
        return Icons.stop_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.help_outline;
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
    final status = agent['status'] as String? ?? 'stopped';

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
                  Icon(_statusIcon(status), color: _statusColor(status), size: 20),
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
                  _statusBadge(status),
                  if (_expiryLabel(agent) != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _showExpiryEditor,
                      child: _expiryBadge(agent),
                    ),
                  ],
                ],
              ),
        actions: [
          if (status == 'running' || status == 'idle')
            IconButton(
              icon: const Icon(Icons.stop, color: AppColors.warning),
              tooltip: '停止智能体',
              onPressed: _stopAgent,
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppColors.success),
              tooltip: '启动智能体',
              onPressed: _startAgent,
            ),
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: AppColors.textSecondary),
            tooltip: '设置过期时间',
            onPressed: _showExpiryEditor,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: '刷新',
            onPressed: _fetchAgent,
          ),
        ],
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
          _buildChatTab(),
          _buildTasksTab(),
          _buildPulseTab(),
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

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String? _expiryLabel(Map<String, dynamic> agent) {
    final expiresAt = agent['expires_at'] as String?;
    if (expiresAt == null) return null;
    try {
      final dt = DateTime.parse(expiresAt);
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return '已过期';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 30) return '${diff.inDays}d';
      return '${(diff.inDays / 30).floor()}mo';
    } catch (_) {
      return null;
    }
  }

  Widget _expiryBadge(Map<String, dynamic> agent) {
    final label = _expiryLabel(agent);
    if (label == null) return const SizedBox.shrink();
    final isExpired = label == '已过期';
    final color = isExpired
        ? AppColors.error
        : label.endsWith('h')
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 11, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 0 : Overview
  // ═══════════════════════════════════════════════════════════

  Widget _buildOverviewTab(Map<String, dynamic> agent) {
    final status = agent['status'] as String? ?? 'stopped';
    final model = agent['model'] as String? ?? 'default';
    final createdAt = agent['created_at'];
    final updatedAt = agent['updated_at'];
    final tokensUsed = (_metrics?['tokens_used'] ?? 0) as num;
    final tokensLimit = (_metrics?['tokens_limit'] ?? 100000) as num;
    final messagesCount = (_metrics?['messages_count'] ?? 0) as num;
    final tasksCompleted = (_metrics?['tasks_completed'] ?? 0) as num;
    final dailyTokens = (_metrics?['daily_tokens_used'] ?? 0) as num;
    final dailyLimit = (_metrics?['daily_token_limit'] ?? 0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status & Controls ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_statusIcon(status), color: _statusColor(status), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent['name'] as String? ?? 'Agent',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '模型: $model',
                            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status == 'running' || status == 'idle')
                      _actionBtn(Icons.stop, '停止', AppColors.warning, _stopAgent)
                    else
                      _actionBtn(Icons.play_arrow, '启动', AppColors.success, _startAgent),
                    _actionBtn(Icons.chat_bubble_outline, '聊天', AppColors.accentPrimary, () {
                      context.push('/agents/${widget.agentId}/chat');
                    }),
                    _actionBtn(Icons.refresh, '刷新', AppColors.textSecondary, _fetchAgent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Role Description ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '角色描述',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!_editingRole)
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                        onPressed: () => setState(() => _editingRole = true),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_editingRole) ...[
                  TextField(
                    controller: _roleController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '描述这个 Agent 的职责...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _roleController.text = agent['role_description'] as String? ?? '';
                          setState(() => _editingRole = false);
                        },
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _savingRole ? null : _saveRoleDescription,
                        child: _savingRole
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('保存'),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    (agent['role_description'] as String?)?.isNotEmpty == true
                        ? agent['role_description'] as String
                        : '暂无角色描述，点击编辑按钮添加。',
                    style: TextStyle(
                      color: (agent['role_description'] as String?)?.isNotEmpty == true
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                      fontSize: 13,
                      fontStyle: (agent['role_description'] as String?)?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Metrics ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.analytics, label: '数据统计'),
                const SizedBox(height: 16),
                _tokenBar('Token 用量', tokensUsed.toDouble(), tokensLimit.toDouble()),
                const SizedBox(height: 12),
                if (dailyLimit > 0)
                  _tokenBar('每日 Token', dailyTokens.toDouble(), dailyLimit.toDouble()),
                if (dailyLimit > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricTile('消息数', messagesCount.toString(), Icons.message)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile('已完成任务', tasksCompleted.toString(), Icons.check_circle)),
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
                    final msg = act['message'] as String? ?? act['content'] as String? ?? '';
                    final ts = act['timestamp'] ?? act['created_at'];
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
                _infoRow('模型', model),
                _infoRow('状态', _statusLabel(status)),
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

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1 : Chat
  // ═══════════════════════════════════════════════════════════

  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            '开始与此智能体聊天',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            '打开聊天界面与此 Agent 互动。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('打开聊天'),
            onPressed: () => context.push('/agents/${widget.agentId}/chat'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2 : Tasks
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
                    decoration: const InputDecoration(labelText: 'Priority'),
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
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
                        child: _creatingTask ? _miniSpinner() : const Text('Create'),
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
                  final name = sched['name'] as String? ?? sched['cron'] as String? ?? 'Schedule';
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
    final title = task['title'] as String? ?? 'Untitled';
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
                  'Priority: ${priority[0].toUpperCase()}${priority.substring(1)}',
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
              const Text('Task Logs', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
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
      child: Text(status, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
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
          title: 'Agenda',
          content: _agendaContent,
          emptyMsg: '未找到日程文件。',
        );
      case 'triggers':
        return _buildTriggersSection();
      case 'monologue':
        return _buildPulseContent(
          icon: Icons.psychology,
          iconColor: AppColors.accentPrimary,
          title: 'Monologue',
          content: _monologueContent,
          emptyMsg: '暂无内心独白内容。',
        );
      case 'history':
        return _buildPulseContent(
          icon: Icons.history,
          iconColor: AppColors.warning,
          title: 'Task History',
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
                Text('Triggers', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                      hintText: 'Define the agent\'s personality and core behavior...',
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

          // Heartbeat
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_outline, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('heartbeat.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
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
                const _SectionHeader(icon: Icons.memory, label: 'Memory Files'),
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
                            Text('$size B', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
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
            const Text('Platform Tools', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._platformTools.map((t) {
              final tool = t as Map<String, dynamic>;
              final id = tool['id']?.toString() ?? '';
              final name = tool['name'] as String? ?? 'Unknown';
              final description = tool['description'] as String? ?? '';
              final category = tool['category'] as String? ?? '';
              final enabled = agentToolMap[id] ?? false;
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
                    Switch(
                      value: enabled,
                      onChanged: (v) => _toggleTool(id, v),
                      activeColor: AppColors.accentPrimary,
                    ),
                  ],
                ),
              );
            }),
          ],

          if (_platformTools.isEmpty && _agentTools.isEmpty)
            _emptyState('No tools available', 'No platform tools or agent-installed tools found.'),

          // Agent-installed Tools
          if (_agentTools.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Agent-Installed Tools', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._agentTools.map((t) {
              final tool = t as Map<String, dynamic>;
              final name = tool['name'] as String? ?? tool['tool_id']?.toString() ?? 'Unknown';
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
                    _viewingSkillName ?? 'Skill',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
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
                child: Text('Skills', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 18), onPressed: _fetchSkillsData),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _skillFiles.isEmpty
              ? _emptyState('No skills', 'No skill files found for this agent.')
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
                        subtitle: Text('$size bytes', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
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
  // TAB 7 : Workspace (file browser)
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
                    _viewingFileName ?? 'File',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
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
                  child: const Text('Root', style: TextStyle(color: AppColors.accentPrimary, fontSize: 13, decoration: TextDecoration.underline)),
                ),
                const Text(' / ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ..._buildBreadcrumbs(),
              ],
              if (_currentPath.isEmpty)
                const Text('Workspace (root)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_currentPath.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: AppColors.textSecondary, size: 18),
                  tooltip: 'Go up',
                  onPressed: () {
                    final parts = _currentPath.split('/');
                    parts.removeLast();
                    _fetchWorkspaceFiles(parts.join('/'));
                  },
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
                  ? _emptyState('Empty directory', 'No files in this directory.')
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
                                      Text('$size bytes', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
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
                child: Text('Activity Log', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
                  ? _emptyState('No activity', 'No activity has been recorded for this agent.')
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
      final type = act['type'] as String? ?? act['event'] as String? ?? '';
      switch (_logFilter) {
        case 'error':
          return type == 'error' || type == 'task_failed';
        case 'user':
          return type == 'chat' || type == 'message' || type == 'task_complete' || type == 'task_completed';
        case 'system':
          return type == 'start' || type == 'started' || type == 'stop' || type == 'stopped' || type == 'tool_call';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildActivityItem(Map<String, dynamic> act) {
    final type = act['type'] as String? ?? act['event'] as String? ?? 'event';
    final message = act['message'] as String? ?? act['content'] as String? ?? '';
    final timestamp = act['timestamp'] ?? act['created_at'];
    final details = act['details'] as String? ?? '';
    final actId = act['id']?.toString() ?? '';
    final isExpanded = _expandedLogId == actId;

    IconData icon;
    Color iconColor;
    switch (type) {
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
      case 'chat':
      case 'message':
        icon = Icons.chat_bubble;
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
                        child: Text(type, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w600)),
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
                const _SectionHeader(icon: Icons.settings, label: 'Model Configuration'),
                const SizedBox(height: 16),
                _buildModelDropdown('Primary Model', _modelCtrl),
                const SizedBox(height: 12),
                _buildModelDropdown('Fallback Model', _fallbackModelCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxTokensCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Tokens', hintText: '4096'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _temperatureCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Temperature', hintText: '0.7'),
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
                        decoration: const InputDecoration(labelText: 'Context Window', hintText: '100'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxToolRoundsCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Tool Rounds', hintText: '50'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Token Limits', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dailyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Daily Token Limit', hintText: 'Unlimited'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _monthlyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Monthly Token Limit', hintText: 'Unlimited'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingSettings ? null : _saveSettings,
                    child: _savingSettings ? _miniSpinner() : const Text('Save Settings'),
                  ),
                ),
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
                      child: Text('Channel Configuration', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'App ID', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'App Secret', isDense: true),
                    ),
                  ] else ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelIdCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Channel ID', isDense: true),
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
                  _settingRow('Type', _channelConfig?['type']?.toString() ?? '-'),
                  _settingRow('Status', _channelConfig?['status']?.toString() ?? '-'),
                  _settingRow('Webhook URL', _channelConfig?['webhook_url']?.toString() ?? '-'),
                  if (_channelConfig?['bot_name'] != null)
                    _settingRow('Bot Name', _channelConfig?['bot_name']?.toString() ?? '-'),
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
                    Text('Danger Zone', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once you delete an agent, there is no going back. Please be certain.',
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
                      const Text('Are you sure?', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                        onPressed: _deleteAgent,
                        child: const Text('Yes, Delete'),
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
                  opt[0].toUpperCase() + opt.substring(1),
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
