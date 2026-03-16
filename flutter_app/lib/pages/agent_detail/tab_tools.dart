part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 3 : Tools
// ═══════════════════════════════════════════════════════════

extension _ToolsTab on _AgentDetailPageState {
  static Map<String, String> _categoryLabelsOf(AppLocalizations l) => {
    'file': l.toolsCategoryFileOps,
    'task': l.toolsCategoryTaskMgmt,
    'communication': l.toolsCategoryComm,
    'search': l.toolsCategorySearch,
    'code': l.toolsCategoryCode,
    'discovery': l.toolsCategoryDiscovery,
    'trigger': l.toolsCategoryTrigger,
    'plaza': l.toolsCategoryPlaza,
    'custom': l.toolsCategoryCustom,
    'general': l.toolsCategoryGeneral,
  };

  Widget _buildToolsTab() {
    final l = AppLocalizations.of(context)!;
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
              Icon(Icons.build, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(l.toolsCount, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Tab bar: platform vs agent-installed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _toolSectionBtn(0, l.toolsPlatform, _platformTools.length),
              const SizedBox(width: 8),
              _toolSectionBtn(1, l.toolsAgentInstalled, _agentTools.length),
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
    final l = AppLocalizations.of(context)!;
    if (_platformTools.isEmpty) {
      return _emptyState(l.toolsNoPlatform, '');
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
        final catLabel = _categoryLabelsOf(l)[cat] ?? cat.toUpperCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(catLabel, style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
            ...tools.map(_buildToolCard),
          ],
        );
      },
    );
  }

  Widget _buildAgentInstalledToolsList() {
    if (_agentTools.isEmpty) {
      final l = AppLocalizations.of(context)!;
      return _emptyState(l.toolsNoInstalled, l.toolsNoInstalledHint);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _agentTools.length,
      itemBuilder: (context, i) => _buildToolCard(_agentTools[i] as Map<String, dynamic>),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final id = tool['id']?.toString() ?? '';
    final name = tool['name'] as String? ?? AppLocalizations.of(context)!.toolsUnknown;
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
                          child: Text(displayName, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
                            child: Text(category, style: TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          mcpServer.isNotEmpty ? '$description · $mcpServer' : description,
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
}
