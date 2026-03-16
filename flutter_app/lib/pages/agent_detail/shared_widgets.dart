import 'package:flutter/material.dart';
import 'package:ohclaw/l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api.dart';

// ── Reusable section header ────────────────────────────────
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const SectionHeader({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Dialog to view a workspace file's content
class FileViewerDialog extends StatefulWidget {
  final String agentId;
  final String path;
  const FileViewerDialog({super.key, required this.agentId, required this.path});

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.readFile(widget.agentId, widget.path);
      if (!mounted) return;
      setState(() { _content = data['content'] as String? ?? ''; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = AppLocalizations.of(context)!.sharedWidgetsReadFailed(e.toString()); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgElevated,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 16, color: AppColors.accentPrimary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(widget.path, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: AppColors.borderSubtle),
            // Content
            Flexible(
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.accentPrimary)))
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppColors.error))))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(_content ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing full task execution result
class TaskDetailSheet extends StatefulWidget {
  final String agentId;
  final String taskId;
  final String title;
  final String desc;
  final String status;
  final VoidCallback onTrigger;
  const TaskDetailSheet({super.key, required this.agentId, required this.taskId, required this.title, required this.desc, required this.status, required this.onTrigger});

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  List<dynamic> _logs = [];
  bool _loading = true;

  static final _filePathRegex = RegExp(r'(?:workspace|skills|knowledge_base)/[\w./_-]+\.[\w]+');

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await ApiService.instance.getTaskLogs(widget.agentId, widget.taskId);
      if (!mounted) return;
      setState(() { _logs = logs; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  if (widget.status == 'pending')
                    TextButton(onPressed: widget.onTrigger, child: Text(AppLocalizations.of(context)!.sharedWidgetsTrigger, style: const TextStyle(color: AppColors.accentPrimary))),
                ],
              ),
            ),
            if (widget.desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Align(alignment: Alignment.centerLeft, child: Text(widget.desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              ),
            Divider(height: 20, color: AppColors.borderSubtle),
            // Logs / Result
            Flexible(
              child: _loading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.accentPrimary)))
                  : _logs.isEmpty
                      ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(AppLocalizations.of(context)!.sharedWidgetsNoRecords, style: TextStyle(color: AppColors.textTertiary))))
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final log = _logs[i] as Map<String, dynamic>;
                            final content = log['message'] as String? ?? log['content'] as String? ?? '';
                            final isResult = content.startsWith('\u2705');
                            if (isResult) {
                              return _buildResultContent(content);
                            }
                            return Text(content, style: TextStyle(color: AppColors.textTertiary, fontSize: 12));
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(String content) {
    final matches = _filePathRegex.allMatches(content).toList();
    if (matches.isEmpty) {
      return SelectableText(content, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6));
    }
    final widgets = <Widget>[];
    int cursor = 0;
    for (final m in matches) {
      if (m.start > cursor) {
        widgets.add(SelectableText(content.substring(cursor, m.start), style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)));
      }
      final path = m.group(0)!;
      widgets.add(
        GestureDetector(
          onTap: () => _openFile(path),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, size: 14, color: AppColors.accentPrimary),
                const SizedBox(width: 4),
                Flexible(child: Text(path, style: const TextStyle(color: AppColors.accentPrimary, fontSize: 12))),
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new, size: 12, color: AppColors.accentPrimary),
              ],
            ),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < content.length) {
      widgets.add(SelectableText(content.substring(cursor), style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  void _openFile(String path) {
    showDialog(
      context: context,
      builder: (ctx) => FileViewerDialog(agentId: widget.agentId, path: path),
    );
  }
}
