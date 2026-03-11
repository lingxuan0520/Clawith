import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/api.dart';

/// 5-step agent creation wizard, ported from React AgentCreate.tsx.
///
/// Steps:
///   0 - Basic Info & Model
///   1 - Personality & Boundaries
///   2 - Skills
///   3 - Permissions
///   4 - Channel (Feishu / Slack / Discord)
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
  List<dynamic> _skills = [];

  // ── Form state (mirrors the React form fields) ────────────
  final Map<String, dynamic> _form = {
    'name': '',
    'role_description': '',
    'personality': '',
    'boundaries': '',
    'primary_model_id': '',
    'fallback_model_id': '',
    'permission_scope_type': 'self',
    'permission_access_level': 'read',
    'template_id': '',
    'max_tokens_per_day': 100000,
    'max_tokens_per_month': 3000000,
    'feishu_app_id': '',
    'feishu_app_secret': '',
    'feishu_encrypt_key': '',
    'slack_bot_token': '',
    'slack_signing_secret': '',
    'discord_application_id': '',
    'discord_bot_token': '',
    'discord_public_key': '',
    'skill_ids': <String>[],
  };

  // ── Text editing controllers (for fields that need them) ──
  final _nameCtrl = TextEditingController();
  final _roleDescCtrl = TextEditingController();
  final _personalityCtrl = TextEditingController();
  final _boundariesCtrl = TextEditingController();
  final _maxDayCtrl = TextEditingController(text: '100000');
  final _maxMonthCtrl = TextEditingController(text: '3000000');
  final _feishuAppIdCtrl = TextEditingController();
  final _feishuAppSecretCtrl = TextEditingController();
  final _feishuEncryptKeyCtrl = TextEditingController();
  final _slackBotTokenCtrl = TextEditingController();
  final _slackSigningSecretCtrl = TextEditingController();
  final _discordAppIdCtrl = TextEditingController();
  final _discordBotTokenCtrl = TextEditingController();
  final _discordPublicKeyCtrl = TextEditingController();

  static const _stepLabels = [
    'Basic Info & Model',
    'Personality & Boundaries',
    'Skills',
    'Permissions',
    'Channel',
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
    _feishuAppIdCtrl.dispose();
    _feishuAppSecretCtrl.dispose();
    _feishuEncryptKeyCtrl.dispose();
    _slackBotTokenCtrl.dispose();
    _slackSigningSecretCtrl.dispose();
    _discordAppIdCtrl.dispose();
    _discordBotTokenCtrl.dispose();
    _discordPublicKeyCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────
  Future<void> _loadResources() async {
    try {
      final results = await Future.wait([
        ApiService.instance.listLlmModels(),
        ApiService.instance.getTemplates(),
        ApiService.instance.listSkills(),
      ]);
      if (!mounted) return;
      setState(() {
        _llmModels = results[0];
        _templates = results[1];
        _skills = results[2];
        _loadingResources = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load resources: $e';
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
    _form['feishu_app_id'] = _feishuAppIdCtrl.text.trim();
    _form['feishu_app_secret'] = _feishuAppSecretCtrl.text.trim();
    _form['feishu_encrypt_key'] = _feishuEncryptKeyCtrl.text.trim();
    _form['slack_bot_token'] = _slackBotTokenCtrl.text.trim();
    _form['slack_signing_secret'] = _slackSigningSecretCtrl.text.trim();
    _form['discord_application_id'] = _discordAppIdCtrl.text.trim();
    _form['discord_bot_token'] = _discordBotTokenCtrl.text.trim();
    _form['discord_public_key'] = _discordPublicKeyCtrl.text.trim();
  }

  // ── Validation per step ───────────────────────────────────
  bool _validateCurrentStep() {
    _syncFormFromControllers();
    switch (_currentStep) {
      case 0:
        if ((_form['name'] as String).isEmpty) {
          _showError('Agent name is required.');
          return false;
        }
        if ((_form['primary_model_id'] as String).isEmpty) {
          _showError('Please select a primary model.');
          return false;
        }
        return true;
      case 1:
      case 2:
      case 3:
      case 4:
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
      data['permission_scope_type'] = _form['permission_scope_type'];
      data['permission_access_level'] = _form['permission_access_level'];
      data['max_tokens_per_day'] = _form['max_tokens_per_day'];
      data['max_tokens_per_month'] = _form['max_tokens_per_month'];

      final skillIds = _form['skill_ids'] as List<String>;
      if (skillIds.isNotEmpty) {
        data['skill_ids'] = skillIds;
      }

      // Channel config — only include if at least one channel field is filled.
      _addIfNotEmpty(data, 'feishu_app_id', _form['feishu_app_id']);
      _addIfNotEmpty(data, 'feishu_app_secret', _form['feishu_app_secret']);
      _addIfNotEmpty(data, 'feishu_encrypt_key', _form['feishu_encrypt_key']);
      _addIfNotEmpty(data, 'slack_bot_token', _form['slack_bot_token']);
      _addIfNotEmpty(
          data, 'slack_signing_secret', _form['slack_signing_secret']);
      _addIfNotEmpty(
          data, 'discord_application_id', _form['discord_application_id']);
      _addIfNotEmpty(data, 'discord_bot_token', _form['discord_bot_token']);
      _addIfNotEmpty(data, 'discord_public_key', _form['discord_public_key']);

      final result = await ApiService.instance.createAgent(data);
      if (!mounted) return;

      final newId = result['id'] as String;
      context.go('/agents/$newId');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Failed to create agent: $e';
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
        title: const Text('Create Agent'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
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
              label: const Text('Previous'),
            ),
          const Spacer(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Next'),
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
              label: Text(_submitting ? 'Creating...' : 'Create Agent'),
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
      case 2:
        return _buildStepSkills();
      case 3:
        return _buildStepPermissions();
      case 4:
        return _buildStepChannel();
      default:
        return const SizedBox.shrink();
    }
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 0 — Basic Info & Model
  // ────────────────────────────────────────────────────────────
  Widget _buildStepBasicInfo() {
    return _StepCard(
      title: 'Basic Info & Model',
      subtitle: 'Provide the core identity and model configuration.',
      children: [
        // Name
        _FieldLabel('Agent Name *'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(hintText: 'e.g. Research Helper'),
        ),
        const SizedBox(height: 18),

        // Role description
        _FieldLabel('Role Description'),
        const SizedBox(height: 6),
        TextField(
          controller: _roleDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Describe what this agent does...'),
        ),
        const SizedBox(height: 18),

        // Template
        _FieldLabel('Template'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: (_form['template_id'] as String).isEmpty
              ? null
              : _form['template_id'] as String,
          hint: 'Select a template (optional)',
          items: _templates.map((t) {
            final id = t['id']?.toString() ?? '';
            final name = t['name']?.toString() ?? id;
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (v) => setState(() => _form['template_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Primary model
        _FieldLabel('Primary Model *'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: (_form['primary_model_id'] as String).isEmpty
              ? null
              : _form['primary_model_id'] as String,
          hint: 'Select primary LLM model',
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final provider = m['provider']?.toString() ?? '';
            final modelName = m['model']?.toString() ?? '';
            return DropdownMenuItem(
              value: id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (provider.isNotEmpty)
                    Text('$provider/$modelName',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => _form['primary_model_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Fallback model
        _FieldLabel('Fallback Model'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: (_form['fallback_model_id'] as String).isEmpty
              ? null
              : _form['fallback_model_id'] as String,
          hint: 'Select fallback LLM model (optional)',
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final provider = m['provider']?.toString() ?? '';
            final modelName = m['model']?.toString() ?? '';
            return DropdownMenuItem(
              value: id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (provider.isNotEmpty)
                    Text('$provider/$modelName',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
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
                  _FieldLabel('Max Tokens / Day'),
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
                  _FieldLabel('Max Tokens / Month'),
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
      title: 'Personality & Boundaries',
      subtitle: 'Define how the agent behaves and what it should avoid.',
      children: [
        _FieldLabel('Personality'),
        const SizedBox(height: 6),
        TextField(
          controller: _personalityCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                'Describe the personality traits, tone, and style of communication...',
          ),
        ),
        const SizedBox(height: 20),
        _FieldLabel('Boundaries'),
        const SizedBox(height: 6),
        TextField(
          controller: _boundariesCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                'List topics or actions the agent must avoid...',
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 2 — Skills
  // ────────────────────────────────────────────────────────────
  Widget _buildStepSkills() {
    final selectedIds = _form['skill_ids'] as List<String>;

    return _StepCard(
      title: 'Skills',
      subtitle: 'Select the skills this agent should have.',
      children: [
        if (_skills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No skills available.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          )
        else
          ..._skills.map((skill) {
            final skillId = skill['id']?.toString() ?? '';
            final skillName = skill['name']?.toString() ?? skillId;
            final skillDesc = skill['description']?.toString() ?? '';
            final isSelected = selectedIds.contains(skillId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected
                    ? AppColors.accentSubtle
                    : AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIds.remove(skillId);
                      } else {
                        selectedIds.add(skillId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isSelected
                              ? AppColors.accentPrimary
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skillName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (skillDesc.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  skillDesc,
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 3 — Permissions
  // ────────────────────────────────────────────────────────────
  Widget _buildStepPermissions() {
    return _StepCard(
      title: 'Permissions',
      subtitle: 'Configure the visibility and access level of this agent.',
      children: [
        // Scope
        _FieldLabel('Permission Scope'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: _form['permission_scope_type'] as String,
          hint: 'Select scope',
          items: const [
            DropdownMenuItem(value: 'self', child: Text('Self only')),
            DropdownMenuItem(value: 'department', child: Text('Department')),
            DropdownMenuItem(value: 'company', child: Text('Company')),
          ],
          onChanged: (v) =>
              setState(() => _form['permission_scope_type'] = v ?? 'self'),
        ),
        const SizedBox(height: 20),

        // Access level
        _FieldLabel('Access Level'),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: _form['permission_access_level'] as String,
          hint: 'Select access level',
          items: const [
            DropdownMenuItem(value: 'read', child: Text('Read')),
            DropdownMenuItem(value: 'write', child: Text('Write')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (v) =>
              setState(() => _form['permission_access_level'] = v ?? 'read'),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  STEP 4 — Channel Configuration
  // ────────────────────────────────────────────────────────────
  Widget _buildStepChannel() {
    return Column(
      children: [
        // Feishu
        _StepCard(
          title: 'Feishu Bot',
          subtitle: 'Optional. Configure Feishu (Lark) integration.',
          children: [
            _FieldLabel('App ID'),
            const SizedBox(height: 6),
            TextField(
              controller: _feishuAppIdCtrl,
              decoration: const InputDecoration(hintText: 'Feishu App ID'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('App Secret'),
            const SizedBox(height: 6),
            TextField(
              controller: _feishuAppSecretCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Feishu App Secret'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Encrypt Key'),
            const SizedBox(height: 6),
            TextField(
              controller: _feishuEncryptKeyCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Feishu Encrypt Key'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Slack
        _StepCard(
          title: 'Slack Bot',
          subtitle: 'Optional. Configure Slack integration.',
          children: [
            _FieldLabel('Bot Token'),
            const SizedBox(height: 6),
            TextField(
              controller: _slackBotTokenCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'xoxb-...'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Signing Secret'),
            const SizedBox(height: 6),
            TextField(
              controller: _slackSigningSecretCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Slack Signing Secret'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Discord
        _StepCard(
          title: 'Discord Bot',
          subtitle: 'Optional. Configure Discord integration.',
          children: [
            _FieldLabel('Application ID'),
            const SizedBox(height: 6),
            TextField(
              controller: _discordAppIdCtrl,
              decoration:
                  const InputDecoration(hintText: 'Discord Application ID'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Bot Token'),
            const SizedBox(height: 6),
            TextField(
              controller: _discordBotTokenCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Discord Bot Token'),
            ),
            const SizedBox(height: 14),
            _FieldLabel('Public Key'),
            const SizedBox(height: 6),
            TextField(
              controller: _discordPublicKeyCtrl,
              decoration:
                  const InputDecoration(hintText: 'Discord Public Key'),
            ),
          ],
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
