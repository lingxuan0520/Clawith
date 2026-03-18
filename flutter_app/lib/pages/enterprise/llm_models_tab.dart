import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../core/theme/app_theme.dart';
import 'section_card.dart';

// ═══════════════════════════════════════════════════════════════
//  LLM MODELS TAB — read-only system model pool
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

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getBillingModels();
      _models = data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[LlmModelsTab] getBillingModels failed: $e');
      // Fallback: try enterprise endpoint which also returns system models
      try {
        final data = await ApiService.instance.listLlmModels();
        _models = data
            .cast<Map<String, dynamic>>()
            .where((m) => m['is_system_model'] == true)
            .toList();
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  String _tierIcon(String? tier) {
    switch (tier) {
      case 'budget': return '💰';
      case 'standard': return '💰💰';
      case 'premium': return '💰💰💰';
      default: return '💰';
    }
  }

  String _tierLabel(String? tier) {
    switch (tier) {
      case 'budget': return '经济';
      case 'standard': return '标准';
      case 'premium': return '高级';
      default: return '标准';
    }
  }

  Color _tierColor(String? tier) {
    switch (tier) {
      case 'budget': return AppColors.success;
      case 'standard': return const Color(0xFF3B82F6);
      case 'premium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_outlined, size: 16, color: AppColors.accentPrimary),
            const SizedBox(width: 6),
            Text('平台模型',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            _buildBadge('${_models.length} 个', AppColors.accentPrimary),
          ],
        ),
        const SizedBox(height: 4),
        Text('统一由平台提供，按实际用量计费。在 Agent 设置中选择模型即可使用。',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 16),
        if (_models.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('暂无可用模型',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._models.map(_buildModelCard),
      ],
    );
  }

  Widget _buildModelCard(Map<String, dynamic> m) {
    final tier = (m['tier'] ?? 'standard') as String;
    final vision = m['supports_vision'] == true;
    final inputPrice = (m['cost_per_input_token_million'] as num?) ?? 0;
    final outputPrice = (m['cost_per_output_token_million'] as num?) ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    (m['label'] ?? m['model'] ?? '') as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  '${_tierIcon(tier)} ${_tierLabel(tier)}',
                  _tierColor(tier),
                ),
                if (vision) ...[
                  const SizedBox(width: 6),
                  _buildBadge('👁 视觉', const Color(0xFF6366F1)),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${(m['model'] ?? '') as String}  ·  输入 \$$inputPrice/1M  ·  输出 \$$outputPrice/1M',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
