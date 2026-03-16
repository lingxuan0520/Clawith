import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../services/api.dart';
import '../stores/auth_store.dart';
import '../stores/app_store.dart';
import '../core/theme/app_theme.dart';
import '../components/tenant_switcher_sheet.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();

  // Step 2 state
  List<Map<String, dynamic>> _templates = [];
  bool _loadingTemplates = false;
  int _selectedTemplateIndex = -1;
  final _agentNameController = TextEditingController();
  bool _creatingAgent = false;

  // Step 3 state
  String? _createdAgentId;
  String _createdAgentName = '';

  @override
  void initState() {
    super.initState();
    // Auto-open the company creation bottom sheet on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCreateCompanySheet();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _agentNameController.dispose();
    super.dispose();
  }

  void _showCreateCompanySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => TenantSwitcherSheet(
        tenants: const [],
        currentTenantId: '',
        onSelect: (_) {},
        onCreate: (name) async {
          final tenant = await ApiService.instance.createTenant({'name': name});
          final newId = tenant['id'] as String;
          // Refresh user info
          final user = await ApiService.instance.getMe();
          if (!mounted) return;
          ref.read(authProvider.notifier).updateUser(user);
          ref.read(appProvider.notifier).setTenant(newId);
          // Advance to step 2
          _goToStep(1);
          _loadTemplates();
        },
      ),
    );
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;
    setState(() => _loadingTemplates = true);
    try {
      final list = await ApiService.instance.getTemplates();
      if (!mounted) return;
      setState(() {
        _templates = list.cast<Map<String, dynamic>>();
        _loadingTemplates = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  Future<void> _createAgentFromTemplate() async {
    if (_selectedTemplateIndex < 0 || _agentNameController.text.trim().isEmpty) return;
    setState(() => _creatingAgent = true);
    try {
      final template = _templates[_selectedTemplateIndex];
      final tenantId = ref.read(appProvider).currentTenantId;
      final agent = await ApiService.instance.createAgent({
        'name': _agentNameController.text.trim(),
        'template_id': template['id'],
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
      });
      if (!mounted) return;
      _createdAgentId = agent['id'] as String?;
      _createdAgentName = agent['name'] as String? ?? _agentNameController.text.trim();
      _goToStep(2);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.onboardingCreateFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingAgent = false);
    }
  }

  void _goToStep(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _finishOnboarding() {
    context.go('/plaza');
    if (_createdAgentId != null) {
      Future.microtask(() {
        if (mounted) context.push('/agents/$_createdAgentId/chat');
      });
    }
  }

  void _skipToPlaza() {
    context.go('/plaza');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStep1(l),
            _buildStep2(l),
            _buildStep3(l),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: Create Company (placeholder — bottom sheet handles it) ───
  Widget _buildStep1(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏢', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(l.onboardingWelcome,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(l.onboardingNameCompany,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _showCreateCompanySheet,
              icon: const Icon(Icons.add_business),
              label: Text(l.onboardingCreateCompany, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Choose Template & Name Agent ─────────────
  Widget _buildStep2(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(l.onboardingRecruitFirst,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(l.onboardingSelectTemplate,
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
          const SizedBox(height: 24),
          if (_loadingTemplates)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            Expanded(
              child: ListView(
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_templates.length, (i) {
                      final t = _templates[i];
                      final selected = _selectedTemplateIndex == i;
                      final name = t['name'] as String? ?? '';
                      final desc = t['description'] as String? ?? '';
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedTemplateIndex = i);
                          if (_agentNameController.text.trim().isEmpty) {
                            _agentNameController.text = name;
                          }
                        },
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 74) / 2,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.accentSubtle : AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.accentPrimary : AppColors.borderSubtle,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_templateEmoji(name),
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 8),
                              Text(name,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_selectedTemplateIndex >= 0) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _agentNameController,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: l.onboardingNameHint,
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textTertiary),
                      ),
                      onSubmitted: (_) => _createAgentFromTemplate(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _creatingAgent || _selectedTemplateIndex < 0 ||
                              _agentNameController.text.trim().isEmpty
                          ? null
                          : _createAgentFromTemplate,
                      child: _creatingAgent
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l.onboardingNextStep, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 3: Start Chatting ───────────────────────────
  Widget _buildStep3(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(l.onboardingAllReady,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Text(l.onboardingAgentReady(_createdAgentName),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _finishOnboarding,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l.onboardingStartChat, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _skipToPlaza,
            child: Text(l.onboardingExplore, style: TextStyle(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  String _templateEmoji(String name) {
    if (name.contains('研究') || name.contains('Research')) return '🔬';
    if (name.contains('项目') || name.contains('Project')) return '📋';
    if (name.contains('客服') || name.contains('Customer')) return '💬';
    if (name.contains('数据') || name.contains('Data')) return '📊';
    if (name.contains('内容') || name.contains('Content')) return '✍️';
    return '🤖';
  }
}
