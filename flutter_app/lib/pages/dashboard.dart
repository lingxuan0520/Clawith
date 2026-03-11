import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final tenantId = ref.read(appProvider).currentTenantId;
      final agents = (await ApiService.instance.listAgents(tenantId: tenantId.isEmpty ? null : tenantId))
          .cast<Map<String, dynamic>>();
      if (!mounted) return;

      // Load tasks and activities for all agents
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

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '-';
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTokens(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '🌙 Late night';
    if (h < 12) return '☀️ Good morning';
    if (h < 18) return '🌤️ Good afternoon';
    return '🌙 Good evening';
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

  String _statusLabel(String s) {
    switch (s) {
      case 'running': return 'Running';
      case 'idle': return 'Standby';
      case 'stopped': return 'Stopped';
      case 'error': return '错误';
      case 'creating': return 'Creating';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allTasks = _tasksByAgent.values.expand((t) => t).toList();
    final activeAgents = _agents.where((a) => a['status'] == 'running' || a['status'] == 'idle').length;
    final pendingTasks = allTasks.where((t) => t['status'] == 'pending' || t['status'] == 'doing').length;
    final totalTokensToday = _agents.fold<num>(0, (s, a) => s + (a['tokens_used_today'] ?? 0));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    Text('${_agents.length} digital employees', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => context.go('/agents/new'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('新建智能体'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_agents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    const Icon(Icons.smart_toy, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    const Text('No digital employees yet', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/agents/new'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('创建第一个智能体'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Stats bar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _statCard('Digital Employees', '${_agents.length}', '$activeAgents online'),
                  _statCard('Active Tasks', '$pendingTasks', 'In progress'),
                  _statCard("Today's Tokens", _formatTokens(totalTokensToday), 'All agents total'),
                  _statCard('Recently Active', '${_agents.where((a) {
                    final la = a['last_active_at'] as String?;
                    if (la == null) return false;
                    return DateTime.now().difference(DateTime.parse(la)).inHours < 1;
                  }).length}', 'Last hour'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Agent list header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(flex: 3, child: Text('AGENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5))),
                  Expanded(flex: 4, child: Text('LATEST ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('TOKEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5))),
                  SizedBox(width: 80, child: Text('ACTIVE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, letterSpacing: 0.5))),
                ],
              ),
            ),
            const Divider(),

            // Agent rows
            ...(_agents..sort((a, b) {
              final aActive = (a['status'] == 'running' || a['status'] == 'idle') ? 1 : 0;
              final bActive = (b['status'] == 'running' || b['status'] == 'idle') ? 1 : 0;
              if (aActive != bActive) return bActive - aActive;
              final aTime = DateTime.tryParse(a['last_active_at'] as String? ?? '') ?? DateTime(2000);
              final bTime = DateTime.tryParse(b['last_active_at'] as String? ?? '') ?? DateTime(2000);
              return bTime.compareTo(aTime);
            })).map((agent) => _agentRow(agent)),

            const SizedBox(height: 32),

            // Global activity
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.show_chart, size: 16, color: AppColors.textTertiary),
                            SizedBox(width: 6),
                            Text('Global Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          ],
                        ),
                        Text('Last 20', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  if (_allActivities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No activity yet', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(4),
                        itemCount: _allActivities.length,
                        itemBuilder: (context, i) {
                          final act = _allActivities[i];
                          final agentName = _agents.firstWhere(
                            (a) => a['id'] == act['agent_id'],
                            orElse: () => {'name': act['agent_id']?.toString().substring(0, 6) ?? '?'},
                          )['name'] as String;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(width: 52, child: Text(_timeAgo(act['created_at'] as String?),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'monospace'))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgTertiary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(agentName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(act['summary'] as String? ?? '',
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _agentRow(Map<String, dynamic> agent) {
    final id = agent['id'] as String;
    final name = agent['name'] as String? ?? 'Agent';
    final status = agent['status'] as String? ?? 'idle';
    final roleDesc = agent['role_description'] as String? ?? '-';
    final usedTokens = agent['tokens_used_today'] as num? ?? 0;
    final maxTokens = agent['max_tokens_per_day'] as num? ?? 0;
    final activity = _activityByAgent[id]?.isNotEmpty == true ? _activityByAgent[id]!.first : null;

    return InkWell(
      onTap: () => context.go('/agents/$id'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Agent info
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.bgTertiary,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Icon(Icons.smart_toy, size: 18, color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 6),
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(status))),
                            const SizedBox(width: 4),
                            Text(_statusLabel(status), style: TextStyle(fontSize: 11, color: _statusColor(status))),
                          ],
                        ),
                        Text(roleDesc, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Activity
            Expanded(
              flex: 4,
              child: activity != null
                  ? Text('${_timeAgo(activity['created_at'] as String?)}  ${activity['summary'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)
                  : const Text('No activity', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
            // Tokens
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_formatTokens(usedTokens)}${maxTokens > 0 ? ' / ${_formatTokens(maxTokens)}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  if (maxTokens > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      height: 3,
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(2)),
                      child: FractionallySizedBox(
                        widthFactor: (usedTokens / maxTokens).clamp(0, 1).toDouble(),
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: (usedTokens / maxTokens) > 0.8 ? AppColors.error : AppColors.textTertiary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Last active
            SizedBox(
              width: 80,
              child: Text(_timeAgo(agent['last_active_at'] as String?),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
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
