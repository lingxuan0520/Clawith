import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api.dart';
import 'step_card.dart';

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

  static const _stepCount = 2;

  List<String> _stepLabels(AppLocalizations l) => [
    l.agentCreateStepBasic,
    l.agentCreateStepPersonality,
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
        ApiService.instance.getBillingModels(),
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
        _errorMessage = AppLocalizations.of(context)!.agentCreateLoadFailed(e.toString());
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
    final l = AppLocalizations.of(context)!;
    switch (_currentStep) {
      case 0:
        if ((_form['name'] as String).isEmpty) {
          _showError(l.agentCreateNameRequired);
          return false;
        }
        if ((_form['primary_model_id'] as String).isEmpty) {
          _showError(l.agentCreateModelRequired);
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
    if (_currentStep < _stepCount - 1) {
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
        _errorMessage = AppLocalizations.of(context)!.agentCreateFailed(e.toString());
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
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text(l.agentCreateTitle),
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
    final l = AppLocalizations.of(context)!;
    final labels = _stepLabels(l);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.bgSecondary,
      child: Row(
        children: List.generate(labels.length, (i) {
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
                      labels[i],
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
                  if (i < labels.length - 1)
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
    final l = AppLocalizations.of(context)!;
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _stepCount - 1;

    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: _goPrevious,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: Text(l.agentCreatePrevStep),
            ),
          const Spacer(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: Text(l.agentCreateNextStep),
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
              label: Text(_submitting ? l.agentCreateCreating : l.agentCreateSubmit),
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
    final l = AppLocalizations.of(context)!;
    return StepCard(
      title: l.agentCreateBasicTitle,
      subtitle: l.agentCreateBasicSubtitle,
      children: [
        // Name
        FieldLabel(l.agentCreateNameLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(hintText: l.agentCreateNameHint),
        ),
        const SizedBox(height: 18),

        // Role description
        FieldLabel(l.agentCreateRoleLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _roleDescCtrl,
          maxLines: 3,
          decoration: InputDecoration(
              hintText: l.agentCreateRoleHint),
        ),
        const SizedBox(height: 18),

        // Template
        FieldLabel(l.agentCreateTemplateLabel),
        const SizedBox(height: 6),
        _buildDropdown<String>(
          value: (_form['template_id'] as String).isEmpty
              ? null
              : _form['template_id'] as String,
          hint: l.agentCreateTemplateHint,
          items: _templates.map((t) {
            final id = t['id']?.toString() ?? '';
            final name = t['name']?.toString() ?? id;
            return DropdownMenuItem(value: id, child: Text(name));
          }).toList(),
          onChanged: (v) => setState(() => _form['template_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Primary model
        FieldLabel(l.agentCreatePrimaryModelLabel),
        const SizedBox(height: 6),
        if (_llmModels.isEmpty)
          Text(l.agentCreateModelTip,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary))
        else
        _buildDropdown<String>(
          value: (_form['primary_model_id'] as String).isEmpty
              ? null
              : _form['primary_model_id'] as String,
          hint: l.agentCreatePrimaryModelHint,
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final tier = m['tier']?.toString() ?? 'standard';
            final tierIcon = tier == 'premium' ? '💰💰💰' : (tier == 'standard' ? '💰💰' : '💰');
            final outputPrice = m['cost_per_output_token_million'];
            final priceHint = outputPrice != null ? ' ~\$${(outputPrice as num).toStringAsFixed(1)}/1M' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$label  $tierIcon$priceHint',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) =>
              setState(() => _form['primary_model_id'] = v ?? ''),
        ),
        const SizedBox(height: 18),

        // Fallback model
        FieldLabel(l.agentCreateFallbackModelLabel),
        const SizedBox(height: 6),
        if (_llmModels.isEmpty)
          const SizedBox.shrink()
        else
        _buildDropdown<String>(
          value: (_form['fallback_model_id'] as String).isEmpty
              ? null
              : _form['fallback_model_id'] as String,
          hint: l.agentCreateFallbackModelHint,
          items: _llmModels.map((m) {
            final id = m['id']?.toString() ?? '';
            final label = (m['label'] as String?)?.isNotEmpty == true
                ? m['label'] as String
                : m['model']?.toString() ?? id;
            final tier = m['tier']?.toString() ?? 'standard';
            final tierIcon = tier == 'premium' ? '💰💰💰' : (tier == 'standard' ? '💰💰' : '💰');
            final outputPrice = m['cost_per_output_token_million'];
            final priceHint = outputPrice != null ? ' ~\$${(outputPrice as num).toStringAsFixed(1)}/1M' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$label  $tierIcon$priceHint',
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
                  FieldLabel(l.agentCreateDailyTokenLimit),
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
                  FieldLabel(l.agentCreateMonthlyTokenLimit),
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
    final l = AppLocalizations.of(context)!;
    return StepCard(
      title: l.agentCreatePersonalityTitle,
      subtitle: l.agentCreatePersonalitySubtitle,
      children: [
        FieldLabel(l.agentCreatePersonalityLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _personalityCtrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: l.agentCreatePersonalityHint,
          ),
        ),
        const SizedBox(height: 20),
        FieldLabel(l.agentCreateBoundariesLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _boundariesCtrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: l.agentCreateBoundariesHint,
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
              TextStyle(color: AppColors.textTertiary, fontSize: 13)),
      decoration: const InputDecoration(),
      dropdownColor: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(12),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }
}
