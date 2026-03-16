import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api.dart';

/// File browser widget for agent workspace, matching React's FileBrowser.
class FileBrowser extends StatefulWidget {
  final String agentId;
  final String initialPath;
  final ValueChanged<String>? onFileSelected;

  const FileBrowser({
    super.key,
    required this.agentId,
    this.initialPath = '',
    this.onFileSelected,
  });

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  List<dynamic> _files = [];
  String _currentPath = '';
  bool _loading = true;
  String? _selectedFile;
  String? _fileContent;
  bool _loadingContent = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final files = await ApiService.instance.listFiles(widget.agentId, path: _currentPath);
      if (mounted) setState(() { _files = files; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openFile(String path) async {
    setState(() { _selectedFile = path; _loadingContent = true; });
    try {
      final result = await ApiService.instance.readFile(widget.agentId, path);
      if (mounted) {
        setState(() {
          _fileContent = result['content'] as String? ?? '';
          _loadingContent = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _fileContent = 'Error loading file: $e'; _loadingContent = false; });
    }
    widget.onFileSelected?.call(path);
  }

  void _navigateToDir(String path) {
    setState(() {
      _currentPath = path;
      _selectedFile = null;
      _fileContent = null;
    });
    _loadFiles();
  }

  void _goUp() {
    if (_currentPath.isEmpty) return;
    final parts = _currentPath.split('/');
    parts.removeLast();
    _navigateToDir(parts.join('/'));
  }

  IconData _fileIcon(String name, bool isDir) {
    if (isDir) return Icons.folder;
    if (name.endsWith('.md')) return Icons.description;
    if (name.endsWith('.py')) return Icons.code;
    if (name.endsWith('.json')) return Icons.data_object;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Icons.settings;
    if (name.endsWith('.txt') || name.endsWith('.log')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // File tree
        SizedBox(
          width: 260,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Path bar
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      if (_currentPath.isNotEmpty)
                        IconButton(
                          onPressed: _goUp,
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          iconSize: 16,
                          color: AppColors.textTertiary,
                          tooltip: 'Go up',
                        ),
                      Expanded(
                        child: Text(
                          _currentPath.isEmpty ? '/' : '/$_currentPath',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadFiles,
                        icon: const Icon(Icons.refresh, size: 16),
                        iconSize: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // File list
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (_files.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Empty directory', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _files.length,
                      itemBuilder: (context, i) {
                        final file = _files[i] as Map<String, dynamic>;
                        final name = file['name'] as String? ?? '';
                        final isDir = file['is_dir'] == true;
                        final path = _currentPath.isEmpty ? name : '$_currentPath/$name';
                        final isSelected = _selectedFile == path;

                        return InkWell(
                          onTap: () => isDir ? _navigateToDir(path) : _openFile(path),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: isSelected ? AppColors.bgHover : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(_fileIcon(name, isDir), size: 16,
                                    color: isDir ? AppColors.warning : AppColors.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis),
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
        ),
        // File content viewer
        Expanded(
          child: _selectedFile == null
              ? Center(
                  child: Text('Select a file to view', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                )
              : _loadingContent
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_selectedFile!,
                                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              _fileContent ?? '',
                              style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
