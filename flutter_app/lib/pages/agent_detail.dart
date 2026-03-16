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
  String _taskFilter = 'pending';
  // ── Schedules ────────────────────────────────────────────
  List<dynamic> _schedules = [];

  // ── Mind ─────────────────────────────────────────────────
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
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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

  // ═══════════════════════════════════════════════════════════
  // TAB 0 : Overview
  // ═══════════════════════════════════════════════════════════

  Widget _buildOverviewTab(Map<String, dynamic> agent) {
    final createdAt = agent['created_at'];
    final lastActiveAt = agent['last_active_at'];
    final creatorName = agent['creator_username'] as String? ?? '';
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
    final llmCallsToday = (agent['llm_calls_today'] ?? 0) as num;
    final maxLlmCalls = (agent['max_llm_calls_per_day'] ?? 100) as num;

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
                _tokenBar('今日 LLM 调用', llmCallsToday.toDouble(), maxLlmCalls.toDouble()),
                const SizedBox(height: 12),
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
                if (creatorName.isNotEmpty)
                  _infoRow('创建者', '@$creatorName'),
                _infoRow('最后活动', _fmtTs(lastActiveAt)),
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
    // Categorize tasks into columns
    final todoTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'pending' || m['status'] == 'todo';
    }).toList();
    final doingTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'doing' || m['status'] == 'running';
    }).toList();
    final doneTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'done' || m['status'] == 'completed';
    }).toList();

    final columns = {
      'pending': ('待办', todoTasks.length + _schedules.length),
      'doing': ('进行中', doingTasks.length),
      'done': ('已完成', doneTasks.length),
    };

    List<dynamic> currentTasks;
    switch (_taskFilter) {
      case 'doing': currentTasks = doingTasks; break;
      case 'done': currentTasks = doneTasks; break;
      default: currentTasks = todoTasks;
    }

    return Column(
      children: [
        // Top bar: tabs + buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns.entries.map((e) {
                      final key = e.key;
                      final label = e.value.$1;
                      final count = e.value.$2;
                      final selected = _taskFilter == key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text('$label $count', style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppColors.textSecondary)),
                          selected: selected,
                          onSelected: (_) => setState(() => _taskFilter = key),
                          selectedColor: AppColors.accentPrimary,
                          backgroundColor: AppColors.bgTertiary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: AppColors.accentPrimary),
                onPressed: _showCreateTaskSheet,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Content list
        Expanded(
          child: _loadingTasks
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _buildTaskColumnContent(_taskFilter, currentTasks),
        ),
      ],
    );
  }

  Widget _buildTaskColumnContent(String column, List<dynamic> tasks) {
    final showSchedules = column == 'pending';
    final hasContent = tasks.isNotEmpty || (showSchedules && _schedules.isNotEmpty);

    if (!hasContent) {
      return _emptyState(
        column == 'pending' ? '暂无待办' : column == 'doing' ? '暂无进行中' : '暂无已完成',
        column == 'pending' ? '创建任务或计划开始吧' : '',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Schedules sub-section in pending tab
        if (showSchedules) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text('SCHEDULED', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          if (_schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('暂无计划', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
          ..._schedules.map((s) => _buildScheduleCard(s as Map<String, dynamic>)),
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Text('TASKS', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
        ],
        // Task cards
        ...tasks.map((t) => _buildTaskCard(t as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> sched) {
    final name = sched['name'] as String? ?? '计划';
    final id = sched['id']?.toString() ?? '';
    final enabled = sched['is_enabled'] == true || sched['enabled'] == true;
    final instruction = sched['instruction'] as String? ?? '';
    final cronExpr = sched['cron_expr'] as String? ?? sched['cron'] as String? ?? '';
    final nextFire = sched['next_run_at'] ?? sched['next_fire_time'];
    final runCount = sched['run_count'] ?? sched['fire_count'] ?? 0;
    final creator = sched['creator_username'] as String? ?? '';

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
              Icon(enabled ? Icons.schedule : Icons.pause_circle_outline, size: 15, color: enabled ? AppColors.accentPrimary : AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              if (creator.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
                  child: Text('@$creator', style: TextStyle(color: AppColors.accentPrimary, fontSize: 9)),
                ),
            ],
          ),
          if (instruction.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(instruction, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (cronExpr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(4)),
                  child: Text(cronExpr, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontFamily: 'monospace')),
                ),
              if (cronExpr.isNotEmpty) const SizedBox(width: 8),
              if (nextFire != null)
                Text('下次: ${_fmtRelative(nextFire)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              if (runCount > 0) ...[
                const SizedBox(width: 8),
                Text('已执行 $runCount 次', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              ],
              const Spacer(),
              InkWell(
                onTap: () => _triggerSchedule(id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.play_circle_outline, size: 18, color: AppColors.accentPrimary),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _deleteSchedule(id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? '无标题';
    final desc = task['description'] as String? ?? '';
    final status = task['status'] as String? ?? 'pending';
    final creator = task['creator_username'] as String? ?? '';
    final taskId = task['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showTaskDetail(taskId, title, desc, status),
      child: Container(
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
                Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                if (status == 'doing' || status == 'running')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('进行中', style: TextStyle(color: AppColors.warning, fontSize: 9)),
                  ),
                if (status == 'done' || status == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('已完成', style: TextStyle(color: AppColors.success, fontSize: 9)),
                  ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (creator.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('@$creator', style: TextStyle(color: AppColors.accentPrimary, fontSize: 10)),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                if (status == 'pending')
                  InkWell(
                    onTap: () => _triggerTask(taskId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('触发', style: TextStyle(color: AppColors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetail(String taskId, String title, String desc, String status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _TaskDetailSheet(
        agentId: widget.agentId,
        taskId: taskId,
        title: title,
        desc: desc,
        status: status,
        onTrigger: () { Navigator.pop(ctx); _triggerTask(taskId); },
      ),
    );
  }

  /// Unified create task/schedule bottom sheet
  void _showCreateTaskSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '1');
    bool isRepeat = false;
    String freq = 'day';
    int execHour = 9;
    int execMinute = 0;
    int dayOfMonth = 1; // 1-31
    int dayOfWeek = 1; // 1=周一 ... 7=周日
    bool hasDeadline = false;
    DateTime? deadline;
    bool creating = false;

    bool needsTime(String f) => f == 'month' || f == 'week' || f == 'day';
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('新建任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(hintText: '任务标题', filled: true, fillColor: AppColors.bgTertiary, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: '任务描述（可选）', filled: true, fillColor: AppColors.bgTertiary, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 14),
                  // Execution mode toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => isRepeat = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                              border: Border.all(color: !isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                            ),
                            child: Center(child: Text('一次性执行', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: !isRepeat ? Colors.white : AppColors.textSecondary))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => isRepeat = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                              border: Border.all(color: isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                            ),
                            child: Center(child: Text('重复执行', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isRepeat ? Colors.white : AppColors.textSecondary))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Repeat settings — two-level: frequency type → sub-settings
                  if (isRepeat) ...[
                    const SizedBox(height: 14),
                    // Level 1: Frequency type dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.repeat, size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          const Text('重复频率', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: freq,
                                isDense: true,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                dropdownColor: AppColors.bgElevated,
                                items: const [
                                  DropdownMenuItem(value: 'day', child: Text('每天')),
                                  DropdownMenuItem(value: 'week', child: Text('每周')),
                                  DropdownMenuItem(value: 'month', child: Text('每月')),
                                  DropdownMenuItem(value: 'hour', child: Text('每小时')),
                                  DropdownMenuItem(value: 'minute', child: Text('每分钟')),
                                ],
                                onChanged: (v) { if (v != null) setSheetState(() => freq = v); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Level 2: Sub-settings based on frequency type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Interval row: "每 [N] 天/周/月/小时/分钟"
                          Row(
                            children: [
                              const Text('每', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 48,
                                height: 34,
                                child: TextField(
                                  controller: intervalCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                                    filled: true,
                                    fillColor: AppColors.bgSecondary,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                {'day': '天', 'week': '周', 'month': '个月', 'hour': '小时', 'minute': '分钟'}[freq] ?? '天',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          // Day-of-month picker — for monthly
                          if (freq == 'month') ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                const Text('几号执行', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: dayOfMonth,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}号'))),
                                      onChanged: (v) { if (v != null) setSheetState(() => dayOfMonth = v); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Day-of-week picker — for weekly
                          if (freq == 'week') ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.view_week_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                const Text('周几执行', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                ...List.generate(7, (i) {
                                  final d = i + 1; // 1=周一 ... 7=周日
                                  final sel = dayOfWeek == d;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() => dayOfWeek = d),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: sel ? AppColors.accentPrimary : AppColors.bgSecondary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(weekLabels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textSecondary)),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                          // Time picker row — only for day/week/month
                          if (needsTime(freq)) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.schedule_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                const Text('几点执行', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                // Hour
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: execHour,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                                      onChanged: (v) { if (v != null) setSheetState(() => execHour = v); },
                                    ),
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                // Minute
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: execMinute,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(12, (i) => i * 5).map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))).toList(),
                                      onChanged: (v) { if (v != null) setSheetState(() => execMinute = v); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('截止时间：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ChoiceChip(
                          label: const Text('永不截止', style: TextStyle(fontSize: 12)),
                          selected: !hasDeadline,
                          onSelected: (_) => setSheetState(() => hasDeadline = false),
                          selectedColor: AppColors.accentPrimary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('设置截止', style: TextStyle(fontSize: 12)),
                          selected: hasDeadline,
                          onSelected: (_) => setSheetState(() {
                            hasDeadline = true;
                            deadline ??= DateTime.now().add(const Duration(days: 30));
                          }),
                          selectedColor: AppColors.accentPrimary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (hasDeadline) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) setSheetState(() => deadline = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderSubtle)),
                          child: Text(
                            deadline != null ? "${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}" : '选择日期',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: titleCtrl.text.trim().isEmpty || creating ? null : () async {
                        setSheetState(() => creating = true);
                        try {
                          if (isRepeat) {
                            // Create schedule
                            final n = int.tryParse(intervalCtrl.text.trim()) ?? 1;
                            final h = execHour;
                            final m = execMinute;
                            String cronExpr;
                            switch (freq) {
                              case 'minute':
                                cronExpr = n == 1 ? '* * * * *' : '*/$n * * * *';
                              case 'hour':
                                cronExpr = n == 1 ? '0 * * * *' : '0 */$n * * *';
                              case 'day':
                                cronExpr = n == 1 ? '$m $h * * *' : '$m $h */$n * *';
                              case 'week':
                                final cronDow = dayOfWeek % 7; // 1=Mon..6=Sat, 7→0=Sun
                                cronExpr = '$m $h * * $cronDow';
                              case 'month':
                                cronExpr = n == 1 ? '$m $h $dayOfMonth * *' : '$m $h $dayOfMonth */$n *';
                              default:
                                cronExpr = '$m $h * * *';
                            }
                            final data = <String, dynamic>{
                              'name': titleCtrl.text.trim(),
                              'instruction': descCtrl.text.trim(),
                              'cron_expr': cronExpr,
                            };
                            if (hasDeadline && deadline != null) {
                              data['due_date'] = deadline!.toIso8601String();
                            }
                            await _api.createSchedule(widget.agentId, data);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showSnack('计划已创建');
                            _fetchSchedules();
                          } else {
                            // Create one-time task
                            await _api.createTask(widget.agentId, {
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                            });
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showSnack('任务已创建');
                            _fetchTasks();
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setSheetState(() => creating = false);
                          _showSnack('创建失败: ${_errMsg(e)}');
                        }
                      },
                      child: creating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('创建'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }


  // ═══════════════════════════════════════════════════════════
  // TAB 2 : Mind
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
          // Soul.md — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _soulExpanded = !_soulExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.accentPrimary, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('soul.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _soulContent?.isNotEmpty == true ? '${_soulContent!.length} 字' : '空',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _soulExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_soulExpanded) ...[
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
                  ] else ...[
                    _codeBlock(_soulContent, '暂无内容，点击编辑按钮创建。'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                        onPressed: () => setState(() => _editingSoul = true),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // HEARTBEAT.md — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _heartbeatExpanded = !_heartbeatExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('HEARTBEAT.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _heartbeatContent?.isNotEmpty == true ? '${_heartbeatContent!.length} 字' : '空',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _heartbeatExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_heartbeatExpanded) ...[
                  const SizedBox(height: 8),
                  _codeBlock(_heartbeatContent, '暂无内容'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Memory Files — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _memoryExpanded = !_memoryExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.memory, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('记忆文件', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '${_memoryFiles.length} 个文件',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _memoryExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_memoryExpanded) ...[
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
                ], // end _memoryExpanded
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

  static const _categoryLabels = {
    'file': '文件操作',
    'task': '任务管理',
    'communication': '通讯',
    'search': '搜索',
    'code': '代码',
    'discovery': '发现',
    'trigger': '触发器',
    'plaza': '广场',
    'custom': '自定义',
    'general': '通用',
  };

  Widget _buildToolsTab() {
    if (_loadingTools) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.build, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Text('工具', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Tab bar: platform vs agent-installed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _toolSectionBtn(0, '平台工具', _platformTools.length),
              const SizedBox(width: 8),
              _toolSectionBtn(1, 'Agent 安装', _agentTools.length),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _toolSection == 0
              ? _buildPlatformToolsList()
              : _buildAgentInstalledToolsList(),
        ),
      ],
    );
  }

  Widget _toolSectionBtn(int index, String label, int count) {
    final active = _toolSection == index;
    return GestureDetector(
      onTap: () => setState(() => _toolSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accentPrimary : AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: active ? null : Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformToolsList() {
    if (_platformTools.isEmpty) {
      return _emptyState('暂无平台工具', '');
    }
    // Group by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in _platformTools) {
      final m = t as Map<String, dynamic>;
      final cat = (m['category'] as String?) ?? 'general';
      grouped.putIfAbsent(cat, () => []).add(m);
    }
    final categories = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final tools = grouped[cat]!;
        final catLabel = _categoryLabels[cat] ?? cat.toUpperCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(catLabel, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            ...tools.map(_buildToolCard),
          ],
        );
      },
    );
  }

  Widget _buildAgentInstalledToolsList() {
    if (_agentTools.isEmpty) {
      return _emptyState('暂无安装的工具', 'Agent 可通过 import_mcp_server 工具自行安装。');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _agentTools.length,
      itemBuilder: (context, i) => _buildToolCard(_agentTools[i] as Map<String, dynamic>),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final id = tool['id']?.toString() ?? '';
    final name = tool['name'] as String? ?? '未知';
    final displayName = tool['display_name'] as String? ?? name;
    final description = tool['description'] as String? ?? '';
    final category = tool['category'] as String? ?? '';
    final enabled = tool['enabled'] == true;
    final toolType = tool['type'] as String? ?? '';
    final configSchema = tool['config_schema'] as Map<String, dynamic>?;
    final hasConfig = configSchema != null && (configSchema['fields'] as List?)?.isNotEmpty == true;
    final isExpanded = _expandedToolId == id;
    final mcpServer = tool['mcp_server_name'] as String? ?? '';
    final agentConfig = (tool['agent_config'] as Map<String, dynamic>?) ?? {};
    final globalConfig = (tool['global_config'] as Map<String, dynamic>?) ?? {};

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
                          child: Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        if (toolType == 'mcp') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('MCP', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.w600)),
                          ),
                        ],
                        if (category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(4)),
                            child: Text(category, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          mcpServer.isNotEmpty ? '$description · $mcpServer' : description,
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
            _buildToolConfigFields(id, configSchema, agentConfig: agentConfig, globalConfig: globalConfig),
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

    // Viewing a skill file content
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
                    // If we came from a sub-folder, go back to it; otherwise go to root
                    if (_skillSubFolder != null && _viewingSkillName != null && _viewingSkillName!.contains('/')) {
                      // Stay in sub-folder view
                    } else {
                      _skillSubFolder = null;
                      _skillSubFiles = [];
                    }
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

    // Viewing files inside a skill folder
    if (_skillSubFolder != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    // If nested (e.g. skill-creator/agents), go up one level
                    if (_skillSubFolder != null && _skillSubFolder!.contains('/')) {
                      final parent = _skillSubFolder!.substring(0, _skillSubFolder!.lastIndexOf('/'));
                      _api.listFiles(widget.agentId, path: 'skills/$parent').then((files) {
                        if (!mounted) return;
                        setState(() {
                          _skillSubFolder = parent;
                          _skillSubFiles = files;
                        });
                      }).catchError((_) {});
                    } else {
                      setState(() {
                        _skillSubFolder = null;
                        _skillSubFiles = [];
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _skillSubFolder!,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  tooltip: '删除技能',
                  onPressed: () => _deleteSkillFile(_skillSubFolder!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _skillSubFiles.isEmpty
                ? _emptyState('文件夹为空', '该技能文件夹下没有文件。')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _skillSubFiles.length,
                    itemBuilder: (ctx, i) {
                      final sf = _skillSubFiles[i] as Map<String, dynamic>;
                      final sfName = sf['name'] as String? ?? '';
                      final sfSize = sf['size'] ?? 0;
                      final sfIsDir = sf['is_dir'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            sfIsDir ? Icons.folder : Icons.insert_drive_file,
                            color: sfIsDir ? AppColors.warning : AppColors.textTertiary,
                            size: 20,
                          ),
                          title: Text(sfName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          subtitle: sfIsDir
                              ? null
                              : Text('$sfSize 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          onTap: () => _openSkillSubFile(sf),
                        ),
                      );
                    },
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
                    // Strip .md extension for display
                    final displayName = name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.auto_fix_high, color: AppColors.accentPrimary, size: 20),
                        title: Text(displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
                          ],
                        ),
                        onTap: () => _openSkillFile(file),
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
                  borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
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

/// Dialog to view a workspace file's content
class _FileViewerDialog extends StatefulWidget {
  final String agentId;
  final String path;
  const _FileViewerDialog({required this.agentId, required this.path});

  @override
  State<_FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<_FileViewerDialog> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.readFile(widget.agentId, widget.path);
      if (!mounted) return;
      setState(() { _content = data['content'] as String? ?? ''; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '读取失败: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgElevated,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 16, color: AppColors.accentPrimary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(widget.path, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(color: AppColors.borderSubtle),
            // Content
            Flexible(
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.accentPrimary)))
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppColors.error))))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(_content ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing full task execution result
class _TaskDetailSheet extends StatefulWidget {
  final String agentId;
  final String taskId;
  final String title;
  final String desc;
  final String status;
  final VoidCallback onTrigger;
  const _TaskDetailSheet({required this.agentId, required this.taskId, required this.title, required this.desc, required this.status, required this.onTrigger});

  @override
  State<_TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<_TaskDetailSheet> {
  List<dynamic> _logs = [];
  bool _loading = true;

  static final _filePathRegex = RegExp(r'(?:workspace|skills|knowledge_base)/[\w./_-]+\.[\w]+');

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await ApiService.instance.getTaskLogs(widget.agentId, widget.taskId);
      if (!mounted) return;
      setState(() { _logs = logs; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  if (widget.status == 'pending')
                    TextButton(onPressed: widget.onTrigger, child: const Text('触发执行', style: TextStyle(color: AppColors.accentPrimary))),
                ],
              ),
            ),
            if (widget.desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(alignment: Alignment.centerLeft, child: Text(widget.desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              ),
            const Divider(height: 20, color: AppColors.borderSubtle),
            // Logs / Result
            Flexible(
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.accentPrimary)))
                  : _logs.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('暂无执行记录', style: TextStyle(color: AppColors.textTertiary))))
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final log = _logs[i] as Map<String, dynamic>;
                            final content = log['message'] as String? ?? log['content'] as String? ?? '';
                            final isResult = content.startsWith('✅');
                            if (isResult) {
                              return _buildResultContent(content);
                            }
                            return Text(content, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(String content) {
    final matches = _filePathRegex.allMatches(content).toList();
    if (matches.isEmpty) {
      return SelectableText(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6));
    }
    final widgets = <Widget>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        widgets.add(SelectableText(content.substring(cursor, m.start), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)));
      }
      final path = m.group(0)!;
      widgets.add(
        GestureDetector(
          onTap: () => _openFile(path),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 14, color: AppColors.accentPrimary),
                const SizedBox(width: 4),
                Flexible(child: Text(path, style: const TextStyle(color: AppColors.accentPrimary, fontSize: 12))),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, size: 12, color: AppColors.accentPrimary),
              ],
            ),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < content.length) {
      widgets.add(SelectableText(content.substring(cursor), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  void _openFile(String path) {
    showDialog(
      context: context,
      builder: (ctx) => _FileViewerDialog(agentId: widget.agentId, path: path),
    );
  }
}
