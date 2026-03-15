import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../stores/app_store.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import '../core/app_lifecycle.dart';

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
      final tenantId = ref.read(appProvider).currentTenantId;
      final data = await ApiService.instance
          .listAgents(tenantId: tenantId.isEmpty ? null : tenantId);
      final agents = data.cast<Map<String, dynamic>>();
      // Sort by updated_at descending (most recent first)
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

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${diff.inDays ~/ 30}个月前';
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
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(
            children: [
              const Text('聊天', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, size: 22),
                color: AppColors.textSecondary,
                tooltip: '招募新员工',
                onPressed: () => context.push('/agents/new'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
      );
    }

    if (_agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            const Text('还没有 Agent', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/agents/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('创建第一个 Agent'),
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
          final role = agent['role'] as String? ?? '';

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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
            title: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: Text(
              role.isNotEmpty ? role : _statusLabel(status),
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _timeAgo(updatedAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            onTap: () => context.push('/agents/$id/chat'),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'running': return '运行中';
      case 'stopped': return '已停止';
      case 'creating': return '创建中';
      case 'error': return '错误';
      default: return '空闲';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
