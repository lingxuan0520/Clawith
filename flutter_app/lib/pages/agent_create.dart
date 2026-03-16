import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/api.dart';

/// 2-step agent creation wizard.
///
/// Steps:
///   0 - Basic Info & Model
///   1 - Personality & Boundaries
class AgentCreatePage extends ConsumerStatefulWidget {
  const AgentCreatePage({super.key});

  @override
  ConsumerState<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends ConsumerState<AgentCreatePage> {
  // ── Wizard state ──────────────────────────────────────────
  int _currentStep = 0;
  bool _submitting = false;
  bool _loadingResources = true;
  String? _errorMessage;

  // ── External data loaded from API ─────────────────────────
  List<dynamic> _llmModels = [];
  List<dynamic> _templates = [];

  // ── Form state (mirrors the React form fields) ────────────
  final Map<String, dynamic> _form = {
    'name': '',
    'role_description': '',
    'personality': '',
    'boundaries': '',
    'primary_model_id': '',
    'fallback_model_id': '',
    'template_id': '',
    'max_tokens_per_day': 100000,
    'max_tokens_per_month': 3000000,
  };

  // ── Text editing controllers (for fields that need them) ──
  final _nameCtrl = TextEditingController();
  final _roleDescCtrl = TextEditingController();
  final _personalityCtrl = TextEditingController();
  final _boundariesCtrl = TextEditingController();
  final _maxDayCtrl = TextEditingController(text: '100000');
  final _maxMonthCtrl = TextEditingController(text: '3000000');

  static const _stepLabels = [
    '基本信息',
    '性格设定',
  ];

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleDescCtrl.dispose();
    _personalityCtrl.dispose();
    _boundariesCtrl.dispose();
    _maxDayCtrl.dispose();
    _maxMonthCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────
  Future<void> _loadResources() async {
    try {
      final results = await Future.wait([
        ApiService.instance.listLlmModels(),
        ApiService.instance.getTemplates(),
      ]);
      if (!mounted) return;
      setState(() {
        _llmModels = results[0];
        _templates = results[1];
        _loadingResources = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载资源失败: $e';
        _loadingResources = false;
      });
    }
  }

  // ── Sync text controllers -> form map ─────────────────────
  void _syncFormFromControllers() {
    _form['name'] = _nameCtrl.text.trim();
    _form['role_description'] = _roleDescCtrl.text.trim();
    _form['personality'] = _personalityCtrl.text.trim();
    _form['boundaries'] = _boundariesCtrl.text.trim();
    _form['max_tokens_per_day'] =
        int.tryParse(_maxDayCtrl.text.trim()) ?? 100000;
    _form['max_tokens_per_month'] =
        int.tryParse(_maxMonthCtrl.text.trim()) ?? 3000000;
  }

  // ── Validation per step ───────────────────────────────────
  bool _validateCurrentStep() {
    _syncFormFromControllers();
    switch (_currentStep) {
      case 0:
        if ((_form['name'] as String).isEmpty) {
          _showError('请输入 Agent 名称');
          return false;
        }
        if ((_form['primary_model_id'] as String).isEmpty) {
          _showError('请选择主模型');
          return false;
        }
        return true;
      case 1:
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Navigation ────────────────────────────────────────────
  void _goNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _stepLabels.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _goPrevious() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ── Submit ────────────────────────────────────────────────
  Future<void> _handleFinish() async {
    if (!_validateCurrentStep()) return;
    _syncFormFromControllers();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Build payload — only include non-empty optional fields.
      final data = <String, dynamic>{
        'name': _form['name'],
        'role_description': _form['role_description'],
        'primary_model_id': _form['primary_model_id'],
      };

      _addIfNotEmpty(data, 'personality', _form['personality']);
      _addIfNotEmpty(data, 'boundaries', _form['boundaries']);
      _addIfNotEmpty(data, 'fallback_model_id', _form['fallback_model_id']);
      _addIfNotEmpty(data, 'template_id', _form['template_id']);
      data['max_tokens_per_day'] = _form['max_tokens_per_day'];
      data['max_tokens_per_month'] = _form['max_tokens_per_month'];

      final result = await ApiService.instance.createAgent(data);
      if (!mounted) return;

      final newId = result['id'] as String;
      context.push('/agents/$newId/chat');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = '创建失败: $e';
      });
    }
  }

  void _addIfNotEmpty(Map<String, dynamic> map, String key, dynamic value) {
    if (value is String && value.isNotEmpty) {
      map[key] = value;
    }
  }

  // ────────────────────────────────────────────────────────────
  //  BUILD
  // ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('招募新员工'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loadingResources
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Error banner
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.error.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.error),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),

        // Step indicator
        _buildStepIndicator(),

        const Divider(height: 1),

        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildCurrentStep(),
          ),
        ),

        // Bottom navigation buttons
        const Divider(height: 1),
        _buildBottomButtons(),
      ],
    );
  }

  // ── Step Indicator ────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.bgSecondary,
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final isActive = i == _currentStep;
          final isCompleted = i < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // Allow jumping to completed steps only.
                if (i < _currentStep) {
                  setState(() => _currentStep = i);
                }
              },
              child: Row(
                children: [
                  // Circle
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.accentPrimary
                          : isCompleted
                              ? AppColors.success
                              : AppColors.bgTertiary,
                      border: Border.all(
                        color: isActive
                            ? AppColors.accentPrimary
                            : isCompleted
                                ? AppColors.success
                                : AppColors.borderDefault,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check,
                            size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textTertiary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                  // Label — only show on wider screens
                  Flexible(
                    child: Text(
                      _stepLabels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.textPrimary
                            : isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  // Connector line between steps
                  if (i < _stepLabels.length - 1)
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.borderSubtle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Bottom navigation buttons ─────────────────────────────
  Widget _buildBottomButtons() {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _stepLabels.length - 1;

    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: _goPrevious,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('上一步'),
            ),
          const Spacer(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('下一步'),
            ),
          if (isLast)
            ElevatedButton.icon(
              onPressed: _submitting ? null : _handleFinish,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_submitting ? '创建中...' : '创建 Agent'),
            ),
        ],
      ),
    );
  }

  // ── Route to current step widget ──────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasicInfo();
      case 1:
        return _buildStepPersonality();
      default:
        return const SizedBox.shrink();
    }
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 0 — Basic Info & Model
  // ────────────────────────────────────────────────────────────
  Widget _buildStepBasicInfo() {
    return _StepCard(
      title: '基本信息与模型',
      subtitle: '设置 Agent 的名称、角色和使用的 AI 模型。',
      children: [
        // Name
        _FieldLabel('Agent 名称 *'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: '例：研究助手'),
        ),
        const SizedBox(height: 18),

        // Role description
        _FieldLabel('角色描述'),
        const SizedBox(height: 6),
        TextField(
          controller: _roleDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: '描述这个 Agent 的职责...'),
        ),
        const SizedBox(height: 18),

        // Template
        _FieldLabel('模板'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: (_form['template_id'] as String).isEmpty
              ? null
              : _form['template_id'] as String,
          hint: '选择模板（可选）',
          items: _templates.map((t) {
            final id = t['id']?.toString() ?? '';
            final name = t['name']?.toString() ?? id;
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (v) => setState(() => _form['template_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Primary model
        _FieldLabel('主模型 *'),
        const SizedBox(height: 6),
        if (_llmModels.isEmpty)
          const Text('提示：请先前往「设置 → 模型池」添加 LLM 模型',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
        else
        _buildDropdown<String>(
          value: (_form['primary_model_id'] as String).isEmpty
              ? null
              : _form['primary_model_id'] as String,
          hint: '选择主 AI 模型',
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final provider = m['provider']?.toString() ?? '';
            final modelName = m['model']?.toString() ?? '';
            final subtitle = provider.isNotEmpty ? ' ($provider/$modelName)' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$label$subtitle',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => _form['primary_model_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Fallback model
        _FieldLabel('备用模型'),
        const SizedBox(height: 6),
        if (_llmModels.isEmpty)
          const SizedBox.shrink()
        else
        _buildDropdown<String>(
          value: (_form['fallback_model_id'] as String).isEmpty
              ? null
              : _form['fallback_model_id'] as String,
          hint: '选择备用模型（可选）',
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final provider = m['provider']?.toString() ?? '';
            final modelName = m['model']?.toString() ?? '';
            final subtitle = provider.isNotEmpty ? ' ($provider/$modelName)' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$label$subtitle',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => _form['fallback_model_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Token limits
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('每日 Token 上限'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _maxDayCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: '100000'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('每月 Token 上限'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _maxMonthCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(hintText: '3000000'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 1 — Personality & Boundaries
  // ────────────────────────────────────────────────────────────
  Widget _buildStepPersonality() {
    return _StepCard(
      title: '性格与边界',
      subtitle: '定义 Agent 的沟通风格和行为边界。',
      children: [
        _FieldLabel('性格特征'),
        const SizedBox(height: 6),
        TextField(
          controller: _personalityCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '描述性格特征、语气和沟通风格...',
          ),
        ),
        const SizedBox(height: 20),
        _FieldLabel('行为边界'),
        const SizedBox(height: 6),
        TextField(
          controller: _boundariesCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '列出 Agent 必须避免的话题或行为...',
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint,
          style:
              const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
      decoration: const InputDecoration(),
      dropdownColor: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(12),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Reusable widgets
// ──────────────────────────────────────────────────────────────

/// Card wrapper for each step's content.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Small label widget used above form fields.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}
