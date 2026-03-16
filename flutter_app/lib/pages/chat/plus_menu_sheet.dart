import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum PlusMenuView { menu, task }

class PlusMenuSheet extends StatefulWidget {
  final VoidCallback onFile;
  final Future<void> Function(String title, String desc) onTaskCreated;
  final Future<void> Function(String name, String instruction, String cronExpr) onScheduleCreated;

  const PlusMenuSheet({
    super.key,
    required this.onFile,
    required this.onTaskCreated,
    required this.onScheduleCreated,
  });

  @override
  State<PlusMenuSheet> createState() => _PlusMenuSheetState();
}

class _PlusMenuSheetState extends State<PlusMenuSheet> {
  PlusMenuView _view = PlusMenuView.menu;

  // Unified task fields
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController(text: '1');
  bool _isRepeat = false;
  String _freq = 'day';
  TimeOfDay _execTime = const TimeOfDay(hour: 9, minute: 0);
  bool _hasDeadline = false;
  DateTime? _deadline;
  bool _creating = false;

  static const _units = [
    ('month', '月'),
    ('week', '周'),
    ('day', '天'),
    ('hour', '小时'),
    ('minute', '分钟'),
  ];
  bool _showExecTime(String f) => f == 'month' || f == 'week' || f == 'day';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _view == PlusMenuView.menu,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _view = PlusMenuView.menu);
        }
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: switch (_view) {
            PlusMenuView.menu => _buildMenu(),
            PlusMenuView.task => _buildTaskForm(),
          },
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.attach_file, color: AppColors.textSecondary),
            title: const Text('发送文件'),
            onTap: widget.onFile,
          ),
          ListTile(
            leading: const Icon(Icons.task_alt, color: AppColors.textSecondary),
            title: const Text('创建任务'),
            subtitle: const Text('一次性或重复执行的任务', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            onTap: () => setState(() => _view = PlusMenuView.task),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTaskForm() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _view = PlusMenuView.menu),
                  child: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                const Text('创建任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '任务标题',
                filled: true,
                fillColor: AppColors.bgTertiary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: '任务描述（可选）',
                filled: true,
                fillColor: AppColors.bgTertiary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 14),
            // Execution mode toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRepeat = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                        border: Border.all(color: !_isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                      ),
                      child: Center(child: Text('一次性执行', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: !_isRepeat ? Colors.white : AppColors.textSecondary))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isRepeat = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                        border: Border.all(color: _isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                      ),
                      child: Center(child: Text('重复执行', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _isRepeat ? Colors.white : AppColors.textSecondary))),
                    ),
                  ),
                ),
              ],
            ),
            // Repeat settings
            if (_isRepeat) ...[
              const SizedBox(height: 14),
              const Text('重复频率', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('每', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _intervalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        filled: true,
                        fillColor: AppColors.bgTertiary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.accentPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _units.map((u) {
                          final sel = _freq == u.$1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => setState(() => _freq = u.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.accentPrimary : AppColors.bgTertiary,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: sel ? AppColors.accentPrimary : AppColors.borderSubtle),
                                ),
                                child: Text(u.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textSecondary)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showExecTime(_freq)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('执行时间：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _execTime);
                        if (t != null) setState(() => _execTime = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderSubtle)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${_execTime.hour.toString().padLeft(2, '0')}:${_execTime.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            const Icon(Icons.schedule, size: 16, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('截止时间：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ChoiceChip(
                    label: const Text('永不截止', style: TextStyle(fontSize: 12)),
                    selected: !_hasDeadline,
                    onSelected: (_) => setState(() => _hasDeadline = false),
                    selectedColor: AppColors.accentPrimary,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('设置截止', style: TextStyle(fontSize: 12)),
                    selected: _hasDeadline,
                    onSelected: (_) => setState(() {
                      _hasDeadline = true;
                      _deadline ??= DateTime.now().add(const Duration(days: 30));
                    }),
                    selectedColor: AppColors.accentPrimary,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (_hasDeadline) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setState(() => _deadline = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderSubtle)),
                    child: Text(
                      _deadline != null ? "${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}" : '选择日期',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _titleCtrl.text.trim().isEmpty || _creating
                    ? null
                    : () async {
                        setState(() => _creating = true);
                        try {
                          if (_isRepeat) {
                            final n = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
                            final h = _execTime.hour;
                            final m = _execTime.minute;
                            String cronExpr;
                            switch (_freq) {
                              case 'minute':
                                cronExpr = n == 1 ? '* * * * *' : '*/$n * * * *';
                              case 'hour':
                                cronExpr = n == 1 ? '0 * * * *' : '0 */$n * * *';
                              case 'day':
                                cronExpr = n == 1 ? '$m $h * * *' : '$m $h */$n * *';
                              case 'week':
                                cronExpr = '$m $h * * 1';
                              case 'month':
                                cronExpr = n == 1 ? '$m $h 1 * *' : '$m $h 1 */$n *';
                              default:
                                cronExpr = '$m $h * * *';
                            }
                            await widget.onScheduleCreated(
                              _titleCtrl.text.trim(),
                              _descCtrl.text.trim(),
                              cronExpr,
                            );
                          } else {
                            await widget.onTaskCreated(
                              _titleCtrl.text.trim(),
                              _descCtrl.text.trim(),
                            );
                          }
                        } catch (e) {
                          if (mounted) setState(() => _creating = false);
                        }
                      },
                child: _creating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('创建'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
