part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 1 : Tasks
// ═══════════════════════════════════════════════════════════

extension _TasksTab on _AgentDetailPageState {
  Widget _buildTasksTab() {
    final l = AppLocalizations.of(context)!;
    // Categorize tasks into columns
    final todoTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'pending' || m['status'] == 'todo';
    }).toList();
    final doingTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'doing' || m['status'] == 'running';
    }).toList();
    final doneTasks = _tasks.where((t) {
      final m = t as Map<String, dynamic>;
      return m['status'] == 'done' || m['status'] == 'completed';
    }).toList();

    final columns = {
      'pending': (l.tasksTodo, todoTasks.length + _schedules.length),
      'doing': (l.tasksInProgress, doingTasks.length),
      'done': (l.tasksCompleted, doneTasks.length),
    };

    List<dynamic> currentTasks;
    switch (_taskFilter) {
      case 'doing': currentTasks = doingTasks; break;
      case 'done': currentTasks = doneTasks; break;
      default: currentTasks = todoTasks;
    }

    return Column(
      children: [
        // Top bar: tabs + buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: columns.entries.map((e) {
                      final key = e.key;
                      final label = e.value.$1;
                      final count = e.value.$2;
                      final selected = _taskFilter == key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text('$label $count', style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppColors.textSecondary)),
                          selected: selected,
                          onSelected: (_) => setState(() => _taskFilter = key),
                          selectedColor: AppColors.accentPrimary,
                          backgroundColor: AppColors.bgTertiary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: AppColors.accentPrimary),
                onPressed: _showCreateTaskSheet,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Content list
        Expanded(
          child: _loadingTasks
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _buildTaskColumnContent(_taskFilter, currentTasks),
        ),
      ],
    );
  }

  Widget _buildTaskColumnContent(String column, List<dynamic> tasks) {
    final l = AppLocalizations.of(context)!;
    final showSchedules = column == 'pending';
    final hasContent = tasks.isNotEmpty || (showSchedules && _schedules.isNotEmpty);

    if (!hasContent) {
      return _emptyState(
        column == 'pending' ? l.tasksNoTodo : column == 'doing' ? l.tasksNoInProgress : l.tasksNoCompleted,
        column == 'pending' ? l.tasksCreateToStart : '',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Schedules sub-section in pending tab
        if (showSchedules) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text('SCHEDULED', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          if (_schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l.tasksNoSchedules, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
          ..._schedules.map((s) => _buildScheduleCard(s as Map<String, dynamic>)),
          if (tasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Text('TASKS', style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
        ],
        // Task cards
        ...tasks.map((t) => _buildTaskCard(t as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> sched) {
    final name = sched['name'] as String? ?? AppLocalizations.of(context)!.tasksScheduleFallback;
    final id = sched['id']?.toString() ?? '';
    final enabled = sched['is_enabled'] == true || sched['enabled'] == true;
    final instruction = sched['instruction'] as String? ?? '';
    final cronExpr = sched['cron_expr'] as String? ?? sched['cron'] as String? ?? '';
    final nextFire = sched['next_run_at'] ?? sched['next_fire_time'];
    final runCount = sched['run_count'] ?? sched['fire_count'] ?? 0;
    final creator = sched['creator_username'] as String? ?? '';

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
              Icon(enabled ? Icons.schedule : Icons.pause_circle_outline, size: 15, color: enabled ? AppColors.accentPrimary : AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              if (creator.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8)),
                  child: Text('@$creator', style: TextStyle(color: AppColors.accentPrimary, fontSize: 9)),
                ),
            ],
          ),
          if (instruction.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(instruction, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (cronExpr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(4)),
                  child: Text(cronExpr, style: TextStyle(color: AppColors.textTertiary, fontSize: 10, fontFamily: 'monospace')),
                ),
              if (cronExpr.isNotEmpty) const SizedBox(width: 8),
              if (nextFire != null)
                Text(AppLocalizations.of(context)!.tasksNextFire(_fmtRelative(nextFire)), style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              if (runCount > 0) ...[
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.tasksRunCount(runCount as int), style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
              ],
              const Spacer(),
              InkWell(
                onTap: () => _triggerSchedule(id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.play_circle_outline, size: 18, color: AppColors.accentPrimary),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _deleteSchedule(id),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? AppLocalizations.of(context)!.tasksNoTitle;
    final desc = task['description'] as String? ?? '';
    final status = task['status'] as String? ?? 'pending';
    final creator = task['creator_username'] as String? ?? '';
    final taskId = task['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showTaskDetail(taskId, title, desc, status),
      child: Container(
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
                Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                if (status == 'doing' || status == 'running')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(AppLocalizations.of(context)!.tasksInProgress, style: TextStyle(color: AppColors.warning, fontSize: 9)),
                  ),
                if (status == 'done' || status == 'completed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(AppLocalizations.of(context)!.tasksCompleted, style: TextStyle(color: AppColors.success, fontSize: 9)),
                  ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (creator.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('@$creator', style: TextStyle(color: AppColors.accentPrimary, fontSize: 10)),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                if (status == 'pending')
                  InkWell(
                    onTap: () => _triggerTask(taskId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppLocalizations.of(context)!.tasksTrigger, style: const TextStyle(color: AppColors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetail(String taskId, String title, String desc, String status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => TaskDetailSheet(
        agentId: widget.agentId,
        taskId: taskId,
        title: title,
        desc: desc,
        status: status,
        onTrigger: () { Navigator.pop(ctx); _triggerTask(taskId); },
      ),
    );
  }

  /// Unified create task/schedule bottom sheet
  void _showCreateTaskSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final intervalCtrl = TextEditingController(text: '1');
    bool isRepeat = false;
    String freq = 'day';
    int execHour = 9;
    int execMinute = 0;
    int dayOfMonth = 1; // 1-31
    int dayOfWeek = 1; // 1=周一 ... 7=周日
    bool hasDeadline = false;
    DateTime? deadline;
    bool creating = false;

    bool needsTime(String f) => f == 'month' || f == 'week' || f == 'day';
    final ll = AppLocalizations.of(context)!;
    final weekLabels = [ll.tasksWeekMon, ll.tasksWeekTue, ll.tasksWeekWed, ll.tasksWeekThu, ll.tasksWeekFri, ll.tasksWeekSat, ll.tasksWeekSun];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ll.tasksNewTask, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(hintText: ll.tasksTaskTitle, filled: true, fillColor: AppColors.bgTertiary, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: ll.tasksTaskDesc, filled: true, fillColor: AppColors.bgTertiary, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 14),
                  // Execution mode toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => isRepeat = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                              border: Border.all(color: !isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                            ),
                            child: Center(child: Text(ll.tasksOneTime, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: !isRepeat ? Colors.white : AppColors.textSecondary))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => isRepeat = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isRepeat ? AppColors.accentPrimary : AppColors.bgTertiary,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                              border: Border.all(color: isRepeat ? AppColors.accentPrimary : AppColors.borderSubtle),
                            ),
                            child: Center(child: Text(ll.tasksRecurring, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isRepeat ? Colors.white : AppColors.textSecondary))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Repeat settings — two-level: frequency type → sub-settings
                  if (isRepeat) ...[
                    const SizedBox(height: 14),
                    // Level 1: Frequency type dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 16, color: AppColors.textTertiary),
                          const SizedBox(width: 8),
                          Text(ll.tasksFrequency, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: freq,
                                isDense: true,
                                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                dropdownColor: AppColors.bgElevated,
                                items: [
                                  DropdownMenuItem(value: 'day', child: Text(ll.tasksDaily)),
                                  DropdownMenuItem(value: 'week', child: Text(ll.tasksWeekly)),
                                  DropdownMenuItem(value: 'month', child: Text(ll.tasksMonthly)),
                                  DropdownMenuItem(value: 'hour', child: Text(ll.tasksHourly)),
                                  DropdownMenuItem(value: 'minute', child: Text(ll.tasksEveryMinute)),
                                ],
                                onChanged: (v) { if (v != null) setSheetState(() => freq = v); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Level 2: Sub-settings based on frequency type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Interval row: "每 [N] 天/周/月/小时/分钟"
                          Row(
                            children: [
                              Text(ll.tasksEvery, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 48,
                                height: 34,
                                child: TextField(
                                  controller: intervalCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                                    filled: true,
                                    fillColor: AppColors.bgSecondary,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                {'day': ll.tasksUnitDay, 'week': ll.tasksUnitWeek, 'month': ll.tasksUnitMonth, 'hour': ll.tasksUnitHour, 'minute': ll.tasksUnitMinute}[freq] ?? ll.tasksUnitDay,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          // Day-of-month picker — for monthly
                          if (freq == 'month') ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Text(ll.tasksDayOfMonth, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: dayOfMonth,
                                      isDense: true,
                                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text(ll.tasksDaySuffix(i + 1)))),
                                      onChanged: (v) { if (v != null) setSheetState(() => dayOfMonth = v); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Day-of-week picker — for weekly
                          if (freq == 'week') ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.view_week_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Text(ll.tasksDayOfWeek, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                ...List.generate(7, (i) {
                                  final d = i + 1; // 1=周一 ... 7=周日
                                  final sel = dayOfWeek == d;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: GestureDetector(
                                      onTap: () => setSheetState(() => dayOfWeek = d),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: sel ? AppColors.accentPrimary : AppColors.bgSecondary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(weekLabels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sel ? Colors.white : AppColors.textSecondary)),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                          // Time picker row — only for day/week/month
                          if (needsTime(freq)) ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: AppColors.borderSubtle),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.schedule_outlined, size: 15, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Text(ll.tasksTimeOfDay, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                const Spacer(),
                                // Hour
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: execHour,
                                      isDense: true,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString().padLeft(2, '0')))),
                                      onChanged: (v) { if (v != null) setSheetState(() => execHour = v); },
                                    ),
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                                // Minute
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: execMinute,
                                      isDense: true,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      dropdownColor: AppColors.bgElevated,
                                      items: List.generate(12, (i) => i * 5).map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))).toList(),
                                      onChanged: (v) { if (v != null) setSheetState(() => execMinute = v); },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(ll.tasksDeadline, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ChoiceChip(
                          label: Text(ll.tasksNoDeadline, style: const TextStyle(fontSize: 12)),
                          selected: !hasDeadline,
                          onSelected: (_) => setSheetState(() => hasDeadline = false),
                          selectedColor: AppColors.accentPrimary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(ll.tasksSetDeadline, style: const TextStyle(fontSize: 12)),
                          selected: hasDeadline,
                          onSelected: (_) => setSheetState(() {
                            hasDeadline = true;
                            deadline ??= DateTime.now().add(const Duration(days: 30));
                          }),
                          selectedColor: AppColors.accentPrimary,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (hasDeadline) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) setSheetState(() => deadline = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderSubtle)),
                          child: Text(
                            deadline != null ? "${deadline!.year}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}" : ll.tasksSelectDate,
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
                      onPressed: titleCtrl.text.trim().isEmpty || creating ? null : () async {
                        setSheetState(() => creating = true);
                        try {
                          if (isRepeat) {
                            // Create schedule
                            final n = int.tryParse(intervalCtrl.text.trim()) ?? 1;
                            final h = execHour;
                            final m = execMinute;
                            String cronExpr;
                            switch (freq) {
                              case 'minute':
                                cronExpr = n == 1 ? '* * * * *' : '*/$n * * * *';
                              case 'hour':
                                cronExpr = n == 1 ? '0 * * * *' : '0 */$n * * *';
                              case 'day':
                                cronExpr = n == 1 ? '$m $h * * *' : '$m $h */$n * *';
                              case 'week':
                                final cronDow = dayOfWeek % 7; // 1=Mon..6=Sat, 7→0=Sun
                                cronExpr = '$m $h * * $cronDow';
                              case 'month':
                                cronExpr = n == 1 ? '$m $h $dayOfMonth * *' : '$m $h $dayOfMonth */$n *';
                              default:
                                cronExpr = '$m $h * * *';
                            }
                            final data = <String, dynamic>{
                              'name': titleCtrl.text.trim(),
                              'instruction': descCtrl.text.trim(),
                              'cron_expr': cronExpr,
                            };
                            if (hasDeadline && deadline != null) {
                              data['due_date'] = deadline!.toIso8601String();
                            }
                            await _api.createSchedule(widget.agentId, data);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showSnack(ll.tasksScheduleCreated);
                            _fetchSchedules();
                          } else {
                            // Create one-time task
                            await _api.createTask(widget.agentId, {
                              'title': titleCtrl.text.trim(),
                              'description': descCtrl.text.trim(),
                            });
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showSnack(ll.tasksTaskCreated);
                            _fetchTasks();
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setSheetState(() => creating = false);
                          _showSnack(ll.tasksCreateFailed(_errMsg(e)));
                        }
                      },
                      child: creating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(ll.commonCreate),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
