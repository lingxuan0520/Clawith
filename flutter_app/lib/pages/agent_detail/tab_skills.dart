part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 4 : Skills
// ═══════════════════════════════════════════════════════════

extension _SkillsTab on _AgentDetailPageState {
  Widget _buildSkillsTab() {
    final l = AppLocalizations.of(context)!;
    if (_loadingSkills) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    // Viewing a skill file content
    if (_viewingSkillContent != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () => setState(() {
                    _viewingSkillContent = null;
                    // If we came from a sub-folder, go back to it; otherwise go to root
                    if (_skillSubFolder != null && _viewingSkillName != null && _viewingSkillName!.contains('/')) {
                      // Stay in sub-folder view
                    } else {
                      _skillSubFolder = null;
                      _skillSubFiles = [];
                    }
                    _viewingSkillName = null;
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _viewingSkillName ?? l.skillsLabel,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accentPrimary, size: 18),
                  tooltip: l.commonEdit,
                  onPressed: _editSkillFile,
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
                  _viewingSkillContent ?? '',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Viewing files inside a skill folder
    if (_skillSubFolder != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    // If nested (e.g. skill-creator/agents), go up one level
                    if (_skillSubFolder != null && _skillSubFolder!.contains('/')) {
                      final parent = _skillSubFolder!.substring(0, _skillSubFolder!.lastIndexOf('/'));
                      _api.listFiles(widget.agentId, path: 'skills/$parent').then((files) {
                        if (!mounted) return;
                        setState(() {
                          _skillSubFolder = parent;
                          _skillSubFiles = files;
                        });
                      }).catchError((_) {});
                    } else {
                      setState(() {
                        _skillSubFolder = null;
                        _skillSubFiles = [];
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _skillSubFolder!,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  tooltip: l.skillsDeleteTooltip,
                  onPressed: () => _deleteSkillFile(_skillSubFolder!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _skillSubFiles.isEmpty
                ? _emptyState(l.skillsFolderEmpty, l.skillsFolderEmptyHint)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _skillSubFiles.length,
                    itemBuilder: (ctx, i) {
                      final sf = _skillSubFiles[i] as Map<String, dynamic>;
                      final sfName = sf['name'] as String? ?? '';
                      final sfSize = sf['size'] ?? 0;
                      final sfIsDir = sf['is_dir'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            sfIsDir ? Icons.folder : Icons.insert_drive_file,
                            color: sfIsDir ? AppColors.warning : AppColors.textTertiary,
                            size: 20,
                          ),
                          title: Text(sfName, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                          subtitle: sfIsDir
                              ? null
                              : Text(l.skillsBytes(sfSize as int), style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          onTap: () => _openSkillSubFile(sf),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Skill list
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.skillsLabel, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.accentPrimary, size: 18),
                tooltip: l.skillsNewTooltip,
                onPressed: _createSkillFile,
              ),
              IconButton(
                icon: const Icon(Icons.download, color: AppColors.accentPrimary, size: 18),
                tooltip: l.skillsImportPreset,
                onPressed: () async {
                  await _fetchSkillPresets();
                  if (!mounted) return;
                  setState(() => _showSkillPresets = !_showSkillPresets);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Skill presets panel
        if (_showSkillPresets && _skillPresets.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.skillsPreset, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillPresets.map((s) {
                    final skill = s as Map<String, dynamic>;
                    final id = skill['id']?.toString() ?? '';
                    final name = skill['name'] as String? ?? l.skillsUnknown;
                    return ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _importSkillPreset(id),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _skillFiles.isEmpty
              ? _emptyState(l.skillsNoSkills, l.skillsNoSkillsHint)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _skillFiles.length,
                  itemBuilder: (ctx, i) {
                    final file = _skillFiles[i] as Map<String, dynamic>;
                    final name = file['name'] as String? ?? '';
                    // Strip .md extension for display
                    final displayName = name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.auto_fix_high, color: AppColors.accentPrimary, size: 20),
                        title: Text(displayName, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
                          ],
                        ),
                        onTap: () => _openSkillFile(file),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
