import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_lifecycle.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../stores/app_store.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  List<Map<String, dynamic>> _agents = [];
  Map<String, List<dynamic>> _tasksByAgent = {};
  Map<String, List<dynamic>> _activityByAgent = {};
  List<Map<String, dynamic>> _allActivities = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!AppLifecycle.instance.isActive) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final agents = (await ApiService.instance.listAgents())
          .cast<Map<String, dynamic>>();
      if (!mounted) return;

      final tasks = <String, List<dynamic>>{};
      final activities = <String, List<dynamic>>{};
      final allActs = <Map<String, dynamic>>[];

      await Future.wait(agents.map((a) async {
        final id = a['id'] as String;
        try {
          tasks[id] = await ApiService.instance.listTasks(id);
        } catch (_) { tasks[id] = []; }
        try {
          final acts = await ApiService.instance.listActivity(id, limit: 5);
          activities[id] = acts;
          for (final act in acts) {
            allActs.add({...act as Map<String, dynamic>, 'agent_id': id});
          }
        } catch (_) { activities[id] = []; }
      }));

      allActs.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _agents = agents;
          _tasksByAgent = tasks;
          _activityByAgent = activities;
          _allActivities = allActs.take(20).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(String? dateStr, AppLocalizations l) {
    if (dateStr == null) return '-';
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inMinutes < 1) return l.timeJustNow;
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    return l.timeDaysAgo(diff.inDays);
  }

  String _formatTokens(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'running': return AppColors.statusRunning;
      case 'idle': return AppColors.statusIdle;
      case 'error': return AppColors.statusError;
      case 'stopped': return AppColors.statusStopped;
      default: return AppColors.textTertiary;
    }
  }

  String _statusLabel(String s, AppLocalizations l) {
    switch (s) {
      case 'running': return l.statusRunning;
      case 'idle': return l.statusStandby;
      case 'stopped': return l.statusStopped;
      case 'error': return l.statusError;
      case 'creating': return l.statusCreating;
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(agentListRefreshProvider, (_, __) => _loadData());
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    final allTasks = _tasksByAgent.values.expand((t) => t).toList();
    final activeAgents = _agents.where((a) => a['status'] == 'running' || a['status'] == 'idle').length;
    final pendingTasks = allTasks.where((t) => t['status'] == 'pending' || t['status'] == 'doing').length;
    final totalTokensToday = _agents.fold<num>(0, (s, a) => s + (a['tokens_used_today'] ?? 0));
    final recentActiveCount = _agents.where((a) {
      final la = a['last_active_at'] as String?;
      if (la == null) return false;
      return DateTime.now().difference(DateTime.parse(la)).inHours < 1;
    }).length;

    return RefreshIndicator(
      color: AppColors.accentPrimary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Stats grid (2x2) ──
          if (_agents.isNotEmpty) ...[
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_alt_rounded,
                  iconColor: AppColors.accentPrimary,
                  label: l.dashboardDigitalEmployees,
                  value: '${_agents.length}',
                  sub: l.dashboardOnlineCount(activeAgents),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.assignment_rounded,
                  iconColor: AppColors.warning,
                  label: l.dashboardActiveTasks,
                  value: '$pendingTasks',
                  sub: l.dashboardProcessing,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.token_rounded,
                  iconColor: AppColors.success,
                  label: l.dashboardTodayTokens,
                  value: _formatTokens(totalTokensToday),
                  sub: l.dashboardAllAgentsTotal,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.flash_on_rounded,
                  iconColor: AppColors.statusIdle,
                  label: l.dashboardRecentActive,
                  value: '$recentActiveCount',
                  sub: l.dashboardLastHour,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Agent list ──
            Text(l.dashboardStaff, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...(_agents..sort((a, b) {
              final aActive = (a['status'] == 'running' || a['status'] == 'idle') ? 1 : 0;
              final bActive = (b['status'] == 'running' || b['status'] == 'idle') ? 1 : 0;
              if (aActive != bActive) return bActive - aActive;
              final aTime = DateTime.tryParse(a['last_active_at'] as String? ?? '') ?? DateTime(2000);
              final bTime = DateTime.tryParse(b['last_active_at'] as String? ?? '') ?? DateTime(2000);
              return bTime.compareTo(aTime);
            })).map((agent) => _buildAgentCard(agent, l)),

            const SizedBox(height: 24),

            // ── Global activity ──
            _buildActivitySection(l),
          ] else
            _buildEmptyState(l),
        ],
      ),
    );
  }

  // ── Stat card ──
  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  // ── Agent card ──
  Widget _buildAgentCard(Map<String, dynamic> agent, AppLocalizations l) {
    final id = agent['id'] as String;
    final name = agent['name'] as String? ?? 'Agent';
    final status = agent['status'] as String? ?? 'idle';
    final roleDesc = agent['role_description'] as String? ?? '';
    final usedTokens = agent['tokens_used_today'] as num? ?? 0;
    final maxTokens = agent['max_tokens_per_day'] as num? ?? 0;
    final activity = _activityByAgent[id]?.isNotEmpty == true ? _activityByAgent[id]!.first : null;
    final statusCol = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/agents/$id'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: avatar + name + status
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.bgTertiary,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Icon(Icons.smart_toy_rounded, size: 20, color: AppColors.textTertiary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                          if (roleDesc.isNotEmpty)
                            Text(roleDesc, style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusCol.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusCol)),
                          const SizedBox(width: 4),
                          Text(_statusLabel(status, l),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusCol)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: tokens + last activity
                Row(
                  children: [
                    // Token usage
                    Icon(Icons.token_rounded, size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTokens(usedTokens)}${maxTokens > 0 ? ' / ${_formatTokens(maxTokens)}' : ''}',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    if (maxTokens > 0) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40, height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (usedTokens / maxTokens).clamp(0, 1).toDouble(),
                            backgroundColor: AppColors.bgTertiary,
                            valueColor: AlwaysStoppedAnimation(
                              (usedTokens / maxTokens) > 0.8 ? AppColors.error : AppColors.accentPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Last active
                    Icon(Icons.schedule_rounded, size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(_timeAgo(agent['last_active_at'] as String?, l),
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
                // Row 3: recent activity summary
                if (activity != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity['summary'] as String? ?? '',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Activity section ──
  Widget _buildActivitySection(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 16, color: AppColors.accentPrimary),
                    const SizedBox(width: 6),
                    Text(l.dashboardGlobalFeed, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                Text(l.dashboardRecent20, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const Divider(height: 20),
          if (_allActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              child: Text(l.dashboardNoFeed, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: _allActivities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final act = _allActivities[i];
                final agentName = _agents.firstWhere(
                  (a) => a['id'] == act['agent_id'],
                  orElse: () => {'name': act['agent_id']?.toString().substring(0, 6) ?? '?'},
                )['name'] as String;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(_timeAgo(act['created_at'] as String?, l),
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(agentName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.accentText)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(act['summary'] as String? ?? '',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(Icons.smart_toy_rounded, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(l.dashboardNoAgents,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
