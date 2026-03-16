part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 0 : Overview
// ═══════════════════════════════════════════════════════════

extension _OverviewTab on _AgentDetailPageState {
  Widget _buildOverviewTab(Map<String, dynamic> agent) {
    final createdAt = agent['created_at'];
    final lastActiveAt = agent['last_active_at'];
    final creatorName = agent['creator_username'] as String? ?? '';
    final tokens = (_metrics?['tokens'] as Map<String, dynamic>?) ?? {};
    final tasks = (_metrics?['tasks'] as Map<String, dynamic>?) ?? {};
    final activity = (_metrics?['activity'] as Map<String, dynamic>?) ?? {};
    final tokensUsed = (tokens['used_month'] ?? 0) as num;
    final tokensLimit = (tokens['limit_month'] ?? 0) as num;
    final dailyTokens = (tokens['used_today'] ?? 0) as num;
    final dailyLimit = (tokens['limit_day'] ?? 0) as num;
    final tasksCompleted = (tasks['done'] ?? 0) as num;
    final tasksTotal = (tasks['total'] ?? 0) as num;
    final actionsLast24h = (activity['actions_last_24h'] ?? 0) as num;
    final llmCallsToday = (agent['llm_calls_today'] ?? 0) as num;
    final maxLlmCalls = (agent['max_llm_calls_per_day'] ?? 100) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metrics ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(icon: Icons.analytics, label: '数据统计'),
                const SizedBox(height: 16),
                _tokenBar('月度 Token', tokensUsed.toDouble(), tokensLimit > 0 ? tokensLimit.toDouble() : 100000),
                const SizedBox(height: 12),
                if (dailyLimit > 0)
                  _tokenBar('每日 Token', dailyTokens.toDouble(), dailyLimit.toDouble()),
                if (dailyLimit > 0) const SizedBox(height: 12),
                _tokenBar('今日 LLM 调用', llmCallsToday.toDouble(), maxLlmCalls.toDouble()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _metricTile('总任务', tasksTotal.toString(), Icons.assignment)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile('已完成', tasksCompleted.toString(), Icons.check_circle)),
                    const SizedBox(width: 12),
                    Expanded(child: _metricTile('24h操作', actionsLast24h.toString(), Icons.trending_up)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Recent Activity ──
          if (_recentActivity.isNotEmpty)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(icon: Icons.history, label: '近期活动'),
                  const SizedBox(height: 12),
                  ..._recentActivity.take(5).map((a) {
                    final act = a as Map<String, dynamic>;
                    final msg = act['summary'] as String? ?? act['message'] as String? ?? '';
                    final ts = act['created_at'] ?? act['timestamp'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(_fmtRelative(ts), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          if (_recentActivity.isNotEmpty) const SizedBox(height: 16),

          // ── Info ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(icon: Icons.info_outline, label: '基本信息'),
                const SizedBox(height: 12),
                _infoRow('Agent ID', widget.agentId),
                _infoRow('创建时间', _fmtTs(createdAt)),
                if (creatorName.isNotEmpty)
                  _infoRow('创建者', '@$creatorName'),
                _infoRow('最后活动', _fmtTs(lastActiveAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenBar(String label, double used, double limit) {
    final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final pct = (ratio * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(
              '${used.toInt()} / ${limit.toInt()} ($pct%)',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation(
              ratio > 0.9
                  ? AppColors.error
                  : ratio > 0.7
                      ? AppColors.warning
                      : AppColors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentPrimary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
