import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ohclaw/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/chat_cache.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../core/app_lifecycle.dart';
import '../stores/app_store.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});
  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!AppLifecycle.instance.isActive) return;
      _loadAgents();
    });
  }

  Future<void> _loadAgents() async {
    try {
      final data = await ApiService.instance.listAgents();
      final agents = data.cast<Map<String, dynamic>>();
      agents.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['updated_at'] as String? ?? '') ?? DateTime(2000);
        final bTime =
            DateTime.tryParse(b['updated_at'] as String? ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      if (mounted) setState(() { _agents = agents; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(String? dateStr, AppLocalizations l) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inMinutes < 1) return l.timeJustNow;
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    if (diff.inDays < 30) return l.timeDaysAgo(diff.inDays);
    return l.timeMonthsAgo(diff.inDays ~/ 30);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running': return AppColors.statusRunning;
      case 'stopped': return AppColors.statusStopped;
      case 'creating': return AppColors.warning;
      case 'error': return AppColors.statusError;
      default: return AppColors.statusIdle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh when agents are created/deleted
    ref.listen(agentListRefreshProvider, (_, __) => _loadAgents());

    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              Text(l.chatListTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, size: 22),
                color: AppColors.textSecondary,
                tooltip: l.chatListRecruitTooltip,
                onPressed: () => context.push('/agents/new'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(l)),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
      );
    }

    if (_agents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAgents,
        color: AppColors.accentPrimary,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Center(child: Text(l.chatListNoAgents, style: TextStyle(color: AppColors.textTertiary, fontSize: 14))),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/agents/new'),
                icon: const Icon(Icons.add, size: 16),
                label: Text(l.chatListCreateFirst),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAgents,
      color: AppColors.accentPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _agents.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) {
          final agent = _agents[i];
          final id = agent['id'] as String;
          final name = agent['name'] as String? ?? 'Agent';
          final status = agent['status'] as String? ?? 'idle';
          final updatedAt = agent['updated_at'] as String?;
          final role = agent['role_description'] as String? ?? '';

          final lastMsg = ChatCache.instance.getLastMessage(id);
          final subtitle = lastMsg != null && lastMsg.content.isNotEmpty
              ? lastMsg.content
              : _statusLabel(status, l);

          final displayTitle = role.isNotEmpty ? '$name — $role' : name;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Stack(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.bgTertiary,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(status),
                      border: Border.all(color: AppColors.bgPrimary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(displayTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _timeAgo(updatedAt, l),
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            onTap: () => context.push('/agents/$id/chat'),
          );
        },
      ),
    );
  }

  String _statusLabel(String status, AppLocalizations l) {
    switch (status) {
      case 'running': return l.statusRunning;
      case 'stopped': return l.statusStopped;
      case 'creating': return l.statusCreating;
      case 'error': return l.statusError;
      default: return l.statusIdle;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
