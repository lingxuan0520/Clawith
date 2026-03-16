import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const _tabLabels = [
    '模型池',
    '工具',
    'Skills',
    // '知识库',     // 2C 不需要
    // '配额管理',  // 2B feature — hidden for 2C
    // '组织架构',  // 2B feature — hidden for 2C
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: const Text(
          '设置',
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
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
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
