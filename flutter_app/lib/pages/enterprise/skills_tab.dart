import 'package:flutter/material.dart';
import '../../services/api.dart';
import '../../core/theme/app_theme.dart';
import 'section_card.dart';

// ═══════════════════════════════════════════════════════════════
//  SKILLS TAB
// ═══════════════════════════════════════════════════════════════
class SkillsTab extends StatefulWidget {
  const SkillsTab({super.key});
  @override
  State<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<SkillsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _skills = [];
  bool _loading = true;
  String _currentPath = '';
  List<Map<String, dynamic>> _files = [];
  bool _filesLoading = false;
  String? _selectedSkillFolder;
  String _selectedSkillName = '';

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listSkills();
      _skills = data.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadFiles(String path) async {
    setState(() {
      _filesLoading = true;
      _currentPath = path;
    });
    try {
      final data = await ApiService.instance.listSkillFiles(path: path);
      _files = data.cast<Map<String, dynamic>>();
    } catch (_) {
      _files = [];
    }
    if (mounted) setState(() => _filesLoading = false);
  }

  void _navigateToFolder(String name) {
    final newPath =
        _currentPath.isEmpty ? name : '$_currentPath/$name';
    _loadFiles(newPath);
  }

  void _navigateUp() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    final newPath = parts.join('/');
    // If we'd go back to the skill folder root (just the folder_name),
    // stay there; if empty, also stay at skill root
    if (newPath.isEmpty || newPath == _selectedSkillFolder) {
      _loadFiles(_selectedSkillFolder ?? '');
    } else {
      _loadFiles(newPath);
    }
  }

  void _selectSkill(Map<String, dynamic> skill) {
    final folderName = (skill['folder_name'] ?? skill['name'] ?? '') as String;
    final name = (skill['name'] ?? '') as String;
    setState(() {
      _selectedSkillFolder = folderName;
      _selectedSkillName = name;
    });
    _loadFiles(folderName);
  }

  void _backToSkillList() {
    setState(() {
      _selectedSkillFolder = null;
      _selectedSkillName = '';
      _currentPath = '';
      _files = [];
    });
  }

  void _viewFile(String name) {
    final filePath = _currentPath.isEmpty ? name : '$_currentPath/$name';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SkillFileViewer(filePath: filePath),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // View B: file browser for selected skill
    if (_selectedSkillFolder != null) {
      return _buildFileBrowserView();
    }

    // View A: skill list (default)
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Skills 注册表',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text(
          '管理全局技能。每个技能是一个包含 SKILL.md 文件的文件夹。'
          "创建 Agent 时选择的技能会被复制到 Agent 的工作区。",
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),

        // Skills list
        if (_loading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_skills.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('暂无技能',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          ..._skills.map(_buildSkillCard),
      ],
    );
  }

  Widget _buildFileBrowserView() {
    // Sub-path relative to the skill folder
    final subPath = _currentPath.length > (_selectedSkillFolder?.length ?? 0)
        ? _currentPath.substring((_selectedSkillFolder?.length ?? 0) + 1)
        : '';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Back button + breadcrumb
        Row(
          children: [
            InkWell(
              onTap: _backToSkillList,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_back,
                    size: 20, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            // Skill name (clickable → back to skill root)
            InkWell(
              onTap: () => _loadFiles(_selectedSkillFolder ?? ''),
              child: Text(_selectedSkillName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentText,
                      decoration: TextDecoration.underline)),
            ),
            // Sub-path parts
            if (subPath.isNotEmpty)
              ...subPath.split('/').asMap().entries.map((entry) {
                final idx = entry.key;
                final part = entry.value;
                final pathUpTo = '$_selectedSkillFolder/${subPath.split('/').sublist(0, idx + 1).join('/')}';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(' / ',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                    InkWell(
                      onTap: () => _loadFiles(pathUpTo),
                      child: Text(part,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accentText,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                );
              }),
            const Spacer(),
            if (subPath.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_upward,
                    size: 16, color: AppColors.textSecondary),
                onPressed: _navigateUp,
                tooltip: '返回上级',
                visualDensity: VisualDensity.compact,
              ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 16, color: AppColors.textSecondary),
              onPressed: () => _loadFiles(_currentPath),
              tooltip: '刷新',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_filesLoading)
          const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPrimary))
        else if (_files.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('空目录',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ),
          )
        else
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _files.asMap().entries.map((entry) {
                final f = entry.value;
                final isLast = entry.key == _files.length - 1;
                final isDir = f['is_dir'] == true || f['type'] == 'directory';
                final name = (f['name'] ?? '') as String;
                return InkWell(
                  onTap: isDir ? () => _navigateToFolder(name) : () => _viewFile(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(
                                  color: AppColors.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDir
                              ? Icons.folder_outlined
                              : Icons.description_outlined,
                          size: 18,
                          color: isDir
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDir
                                      ? AppColors.accentText
                                      : AppColors.textPrimary)),
                        ),
                        if (f['size'] != null)
                          Text(_formatBytes(f['size'] as int),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final name = (skill['name'] ?? '') as String;
    final description = (skill['description'] ?? '') as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectSkill(skill),
        borderRadius: BorderRadius.circular(12),
        child: SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 20, color: AppColors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.textPrimary)),
                    if (description.isNotEmpty)
                      Text(description,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skill File Viewer (bottom sheet) ─────────────────────────
class SkillFileViewer extends StatefulWidget {
  final String filePath;
  const SkillFileViewer({super.key, required this.filePath});
  @override
  State<SkillFileViewer> createState() => _SkillFileViewerState();
}

class _SkillFileViewerState extends State<SkillFileViewer> {
  String _content = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.readSkillFile(widget.filePath);
      if (mounted) {
        setState(() {
          _content = (data['content'] ?? '') as String;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(fileName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                    ? Center(child: Text('加载失败: $_error',
                        style: const TextStyle(color: AppColors.error, fontSize: 13)))
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _content,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
