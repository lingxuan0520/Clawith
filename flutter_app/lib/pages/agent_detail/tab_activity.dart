part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 6 : Activity Log
// ═══════════════════════════════════════════════════════════

extension _ActivityTab on _AgentDetailPageState {
  Widget _buildActivityTab() {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Icon(Icons.history, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.activityTitle, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _segmentedControl(
                options: const ['all', 'user', 'system', 'error'],
                selected: _logFilter,
                onChanged: (v) {
                  setState(() => _logFilter = v);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingActivity
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _filteredActivities.isEmpty
                  ? _emptyState(l.activityNoActivity, l.activityNoActivityHint)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (ctx, i) {
                        final act = _filteredActivities[i] as Map<String, dynamic>;
                        return _buildActivityItem(act);
                      },
                    ),
        ),
      ],
    );
  }

  List<dynamic> get _filteredActivities {
    if (_logFilter == 'all') return _activities;
    return _activities.where((a) {
      final act = a as Map<String, dynamic>;
      final type = act['action_type'] as String? ?? act['type'] as String? ?? '';
      switch (_logFilter) {
        case 'error':
          return type == 'error' || type == 'task_failed';
        case 'user':
          return type == 'chat_reply' || type == 'chat' || type == 'message'
              || type == 'web_msg_sent' || type == 'agent_msg_sent' || type == 'feishu_msg_sent'
              || type == 'task_created' || type == 'task_updated' || type == 'task_complete' || type == 'task_completed';
        case 'system':
          return type == 'heartbeat' || type == 'schedule_run' || type == 'tool_call'
              || type == 'file_written' || type == 'plaza_post'
              || type == 'start' || type == 'started' || type == 'stop' || type == 'stopped';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildActivityItem(Map<String, dynamic> act) {
    final type = act['action_type'] as String? ?? act['type'] as String? ?? 'event';
    final message = act['summary'] as String? ?? act['message'] as String? ?? '';
    final timestamp = act['created_at'] ?? act['timestamp'];
    final detailRaw = act['detail'] ?? act['details'];
    final details = detailRaw is String ? detailRaw : (detailRaw != null ? detailRaw.toString() : '');
    final actId = act['id']?.toString() ?? '';
    final isExpanded = _expandedLogId == actId;

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'task_created':
      case 'task_updated':
      case 'task_complete':
      case 'task_completed':
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case 'error':
      case 'task_failed':
        icon = Icons.error;
        iconColor = AppColors.error;
        break;
      case 'chat_reply':
      case 'web_msg_sent':
      case 'agent_msg_sent':
      case 'feishu_msg_sent':
      case 'chat':
      case 'message':
        icon = Icons.chat_bubble;
        iconColor = AppColors.accentPrimary;
        break;
      case 'heartbeat':
        icon = Icons.favorite;
        iconColor = AppColors.warning;
        break;
      case 'schedule_run':
        icon = Icons.schedule;
        iconColor = AppColors.textSecondary;
        break;
      case 'file_written':
        icon = Icons.insert_drive_file;
        iconColor = AppColors.accentPrimary;
        break;
      case 'plaza_post':
        icon = Icons.forum;
        iconColor = AppColors.accentPrimary;
        break;
      case 'start':
      case 'started':
        icon = Icons.play_circle;
        iconColor = AppColors.success;
        break;
      case 'stop':
      case 'stopped':
        icon = Icons.stop_circle;
        iconColor = AppColors.warning;
        break;
      case 'tool_call':
        icon = Icons.build;
        iconColor = AppColors.accentPrimary;
        break;
      default:
        icon = Icons.circle;
        iconColor = AppColors.textTertiary;
    }

    return GestureDetector(
      onTap: details.isNotEmpty
          ? () => setState(() => _expandedLogId = isExpanded ? null : actId)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(_activityTypeLabel(type), style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(_fmtTs(timestamp), style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: isExpanded ? null : 3,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ],
                  if (isExpanded && details.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(6)),
                      child: SelectableText(
                        details,
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _activityTypeLabel(String type) {
    final l = AppLocalizations.of(context)!;
    switch (type) {
      case 'chat_reply': return l.activityTypeChatReply;
      case 'web_msg_sent': return l.activityTypeWebMessage;
      case 'agent_msg_sent': return l.activityTypeAgentMessage;
      case 'feishu_msg_sent': return l.activityTypeFeishuMessage;
      case 'tool_call': return l.activityTypeToolCall;
      case 'task_created': return l.activityTypeTaskCreate;
      case 'task_updated': return l.activityTypeTaskUpdate;
      case 'task_complete': case 'task_completed': return l.activityTypeTaskComplete;
      case 'task_failed': return l.activityTypeTaskFail;
      case 'error': return l.activityTypeError;
      case 'heartbeat': return l.activityTypeHeartbeat;
      case 'schedule_run': return l.activityTypeSchedule;
      case 'file_written': return l.activityTypeFileWrite;
      case 'plaza_post': return l.activityTypePlazaPost;
      case 'start': case 'started': return l.activityTypeStart;
      case 'stop': case 'stopped': return l.activityTypeStop;
      default: return type;
    }
  }
}
