part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 5 : Workspace (file browser)
// ═══════════════════════════════════════════════════════════

extension _WorkspaceTab on _AgentDetailPageState {
  Widget _buildWorkspaceTab() {
    // Viewing a file
    if (_viewingFileContent != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() {
                    _viewingFileContent = null;
                    _viewingFileName = null;
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _viewingFileName ?? '文件',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                  tooltip: '编辑',
                  onPressed: _editWorkspaceFile,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: SelectableText(
                  _viewingFileContent ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Breadcrumb
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              if (_currentPath.isNotEmpty) ...[
                InkWell(
                  onTap: () => _fetchWorkspaceFiles(),
                  child: const Text('根目录', style: TextStyle(color: AppColors.accentPrimary, fontSize: 13, decoration: TextDecoration.underline)),
                ),
                const Text(' / ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                ..._buildBreadcrumbs(),
              ],
              if (_currentPath.isEmpty)
                const Text('工作区 (根目录)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_currentPath.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_upward, color: AppColors.textSecondary, size: 18),
                  tooltip: '返回上级',
                  onPressed: () {
                    final parts = _currentPath.split('/');
                    parts.removeLast();
                    _fetchWorkspaceFiles(parts.join('/'));
                  },
                ),
              IconButton(
                icon: const Icon(Icons.create_new_folder, color: AppColors.textSecondary, size: 18),
                tooltip: '新建文件夹',
                onPressed: _createWorkspaceFolder,
              ),
              IconButton(
                icon: const Icon(Icons.note_add, color: AppColors.textSecondary, size: 18),
                tooltip: '新建文件',
                onPressed: _createWorkspaceFile,
              ),
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppColors.textSecondary, size: 18),
                tooltip: '上传文件',
                onPressed: _uploadWorkspaceFile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // File List
        Expanded(
          child: _loadingWorkspace
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
              : _workspaceFiles.isEmpty
                  ? _emptyState('空目录', '该目录下没有文件。')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _workspaceFiles.length,
                      itemBuilder: (ctx, i) {
                        final file = _workspaceFiles[i] as Map<String, dynamic>;
                        final name = file['name'] as String? ?? '';
                        final isDir = file['is_directory'] == true || file['type'] == 'directory';
                        final size = file['size'] ?? 0;
                        final modified = file['modified'] ?? file['updated_at'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              isDir ? Icons.folder : _fileIcon(name),
                              color: isDir ? AppColors.warning : AppColors.textTertiary,
                              size: 20,
                            ),
                            title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            subtitle: isDir
                                ? null
                                : Row(
                                    children: [
                                      Text('$size 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                      if (modified != null) ...[
                                        const SizedBox(width: 12),
                                        Text(_fmtRelative(modified), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                            trailing: isDir
                                ? const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18)
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                    onPressed: () => _deleteWorkspaceFile(name),
                                  ),
                            onTap: () => _openWorkspaceFile(file),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'py':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'md':
        return Icons.article;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'txt':
        return Icons.text_snippet;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  List<Widget> _buildBreadcrumbs() {
    final parts = _currentPath.split('/');
    final widgets = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      final isLast = i == parts.length - 1;
      final pathUpTo = parts.sublist(0, i + 1).join('/');
      if (isLast) {
        widgets.add(Text(parts[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)));
      } else {
        widgets.add(InkWell(
          onTap: () => _fetchWorkspaceFiles(pathUpTo),
          child: Text(parts[i], style: const TextStyle(color: AppColors.accentPrimary, fontSize: 13, decoration: TextDecoration.underline)),
        ));
        widgets.add(const Text(' / ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)));
      }
    }
    return widgets;
  }
}
