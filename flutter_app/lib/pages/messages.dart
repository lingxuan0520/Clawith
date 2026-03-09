import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../services/api.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  Timer? _refreshTimer;

  static const _actionIcons = <String, String>{
    'text': '\u{1F4AC}',
    'notify': '\u{00B7}',
    'consult': '?',
    'task_delegate': '+',
  };

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ApiService.instance.getInbox(limit: 100);
      if (mounted) {
        setState(() {
          _messages = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markRead(String id) async {
    try {
      await ApiService.instance.markRead(id);
      _loadMessages();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.instance.markAllRead();
      _loadMessages();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _messages.where((m) => m['read_at'] == null).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Messages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text('Mark all read ($unreadCount)', style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_messages.isEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(60),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('No messages yet', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    final isRead = msg['read_at'] != null;
                    final msgType = msg['msg_type'] as String? ?? '';
                    return InkWell(
                      onTap: isRead ? null : () => _markRead(msg['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : AppColors.bgElevated.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(left: BorderSide(
                            color: isRead ? Colors.transparent : AppColors.accentPrimary,
                            width: 3,
                          )),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_actionIcons[msgType] ?? '\u{00B7}', style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(msg['sender_name'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('\u{2192} ${msg['receiver_name'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                const Spacer(),
                                Text(_formatTime(msg['created_at'] as String?),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                if (!isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentPrimary),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              msg['content'] as String? ?? '',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
