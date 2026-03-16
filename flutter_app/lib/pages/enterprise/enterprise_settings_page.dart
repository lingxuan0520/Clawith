import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import 'llm_models_tab.dart';
import 'tools_tab.dart';
import 'skills_tab.dart';

// ─── Enterprise Settings Page ─────────────────────────────────
class EnterpriseSettingsPage extends ConsumerStatefulWidget {
  const EnterpriseSettingsPage({super.key});

  @override
  ConsumerState<EnterpriseSettingsPage> createState() =>
      _EnterpriseSettingsPageState();
}

class _EnterpriseSettingsPageState
    extends ConsumerState<EnterpriseSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabLabels = [
      l.enterpriseModelPool,
      l.enterpriseTools,
      'Skills',
    ];
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          l.enterpriseSettings,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accentPrimary,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabAlignment: TabAlignment.start,
          tabs: tabLabels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LlmModelsTab(),
          ToolsTab(),
          SkillsTab(),
          // _KnowledgeBaseTab(),  // 2C 不需要
          // _QuotasUsersTab(),  // 2B feature — hidden for 2C
          // _OrgTab(),          // 2B feature — hidden for 2C
        ],
      ),
    );
  }
}
