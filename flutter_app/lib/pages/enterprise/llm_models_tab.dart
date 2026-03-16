import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../../services/api.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'section_card.dart';

Dio get _dio => ApiClient.instance.dio;

// ═══════════════════════════════════════════════════════════════
//  LLM MODELS TAB
// ═══════════════════════════════════════════════════════════════
class LlmModelsTab extends StatefulWidget {
  const LlmModelsTab({super.key});
  @override
  State<LlmModelsTab> createState() => _LlmModelsTabState();
}

class _LlmModelsTabState extends State<LlmModelsTab>
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

  static List<(String, String)> _providersOf(AppLocalizations l) => [
    ('anthropic', 'Anthropic'),
    ('openai', 'OpenAI'),
    ('deepseek', 'DeepSeek'),
    ('kimi', l.llmKimiProvider),
    ('minimax', 'MiniMax'),
    ('qwen', 'Qwen (DashScope)'),
    ('zhipu', 'Zhipu'),
    ('openrouter', 'OpenRouter'),
    ('custom', l.llmCustomProvider),
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
      _showError(AppLocalizations.of(context)!.llmSaveFailed);
    }
  }

  Future<void> _deleteModel(String id) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(l.llmDeleteTitle,
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(l.llmDeleteConfirm,
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text(l.commonDelete, style: const TextStyle(color: AppColors.error))),
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
            title: Text(l.llmModelInUse,
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
                l.llmModelInUseConfirm(agents),
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.commonCancel)),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.llmForceDelete,
                      style: const TextStyle(color: AppColors.error))),
            ],
          ),
        );
        if (forceConfirmed == true) {
          await _dio.delete('/enterprise/llm-models/$id',
              queryParameters: {'force': 'true'});
          _loadModels();
        }
      } else {
        _showError(l.llmDeleteFailed);
      }
    }
  }

  Future<void> _testModel() async {
    final apiKey = _apiKeyCtl.text.trim();
    if (apiKey.isEmpty && _editingModelId != null) {
      _showError(AppLocalizations.of(context)!.llmTestNeedKey);
      return;
    }
    if (_modelCtl.text.trim().isEmpty || apiKey.isEmpty) {
      _showError(AppLocalizations.of(context)!.llmTestFillRequired);
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
      _showError(AppLocalizations.of(context)!.llmTestFailed);
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
    final l = AppLocalizations.of(context)!;
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
            label: Text(l.llmAddModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Add/Edit form
        if (_showForm) ...[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingModelId != null ? l.llmEditModel : l.llmAddModel,
                  style: TextStyle(
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
                          Text(l.llmProvider,
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
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary),
                                items: _providersOf(l)
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
                          Text(l.llmModelName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _modelCtl,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(
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
                          Text(l.llmDisplayName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _labelCtl,
                            style: TextStyle(
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
                          Text(l.llmCustomBaseUrl,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _baseUrlCtl,
                            style: TextStyle(
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
                    Text('API Key',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _apiKeyCtl,
                      onChanged: (_) => setState(() {}),
                      obscureText: true,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _editingModelId != null
                            ? l.llmKeepUnchanged
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
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text: l.llmVisionSupport,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary)),
                            TextSpan(
                                text:
                                    ' — ${l.llmVisionHint}',
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
                      child: Text(l.commonCancel),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _testing || _modelCtl.text.isEmpty || _apiKeyCtl.text.isEmpty
                          ? null
                          : _testModel,
                      child: _testing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary))
                          : Text(l.llmTest),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _modelCtl.text.isNotEmpty &&
                                  (_editingModelId != null ||
                                      _apiKeyCtl.text.isNotEmpty)
                              ? _saveModel
                              : null,
                      child: Text(l.commonSave),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(l.llmNoModels,
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
    final l = AppLocalizations.of(context)!;
    final enabled = m['enabled'] == true;
    final vision = m['supports_vision'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (m['label'] ?? m['model'] ?? '') as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m['provider']}/${m['model']}${m['base_url'] != null && (m['base_url'] as String).isNotEmpty ? ' \u00b7 ${m['base_url']}' : ''}',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(enabled ? l.llmEnabled : l.llmDisabled,
                enabled ? AppColors.success : AppColors.warning),
            if (vision) ...[
              const SizedBox(width: 6),
              _buildBadge(l.llmVision, const Color(0xFF6366F1)),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _openEditForm(m),
              tooltip: l.commonEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.error),
              onPressed: () => _deleteModel(m['id'] as String),
              tooltip: l.commonDelete,
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
