import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api.dart';

/// One-click agent creation from template picker.
class AgentCreatePage extends ConsumerStatefulWidget {
  const AgentCreatePage({super.key});

  @override
  ConsumerState<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends ConsumerState<AgentCreatePage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await ApiService.instance.getTemplates();
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onTemplateTap(Map<String, dynamic> template) {
    final nameCtrl = TextEditingController(
      text: template['display_name'] ?? template['name'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TemplateBottomSheet(
        template: template,
        nameController: nameCtrl,
        onSubmit: (name) {
          Navigator.pop(ctx);
          _createAgent(template, name);
        },
      ),
    );
  }

  Future<void> _createAgent(Map<String, dynamic> template, String name) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = <String, dynamic>{
        'template_id': template['id'],
        'name': name.trim(),
      };
      final result = await ApiService.instance.createAgent(data);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      final newId = result['id'] as String;
      context.push('/agents/$newId/chat');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creation failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Hire AI Employee'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load templates',
                          style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadTemplates();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            'Pick a template to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Template grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final t = _templates[index] as Map<String, dynamic>;
              return _TemplateCard(
                template: t,
                onTap: () => _onTemplateTap(t),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Template Card ─────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final Map<String, dynamic> template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = template['icon'] ?? '🤖';
    final name = template['display_name'] ?? template['name'] ?? 'Agent';
    final description = template['description'] ?? '';
    final tier = template['recommended_model_tier'] ?? 'standard';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icon
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),

            // Name
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Description (2 lines)
            Expanded(
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tier badge
            _TierBadge(tier: tier),
          ],
        ),
      ),
    );
  }
}

// ─── Tier Badge ────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bgColor;
    final Color textColor;

    switch (tier) {
      case 'budget':
        label = '💰 Budget';
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
      case 'premium':
        label = '👑 Premium';
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warning;
      default:
        label = '⭐ Standard';
        bgColor = AppColors.accentPrimary.withValues(alpha: 0.15);
        textColor = AppColors.accentPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// ─── Bottom Sheet ──────────────────────────────────────────

class _TemplateBottomSheet extends StatefulWidget {
  const _TemplateBottomSheet({
    required this.template,
    required this.nameController,
    required this.onSubmit,
  });

  final Map<String, dynamic> template;
  final TextEditingController nameController;
  final void Function(String name) onSubmit;

  @override
  State<_TemplateBottomSheet> createState() => _TemplateBottomSheetState();
}

class _TemplateBottomSheetState extends State<_TemplateBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final icon = template['icon'] ?? '🤖';
    final name = template['display_name'] ?? template['name'] ?? 'Agent';
    final description = template['description'] ?? '';
    final tier = template['recommended_model_tier'] ?? 'standard';
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + Name
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _TierBadge(tier: tier),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Name field
          Text(
            'Name',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.nameController,
            decoration: InputDecoration(
              hintText: 'Give your agent a name',
              filled: true,
              fillColor: AppColors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accentPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Create button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.nameController.text.trim().isEmpty
                  ? null
                  : () => widget.onSubmit(widget.nameController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.bgTertiary,
              ),
              child: const Text(
                'Create Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
