part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 2 : Mind
// ═══════════════════════════════════════════════════════════

extension _MindTab on _AgentDetailPageState {
  Widget _buildMindTab() {
    if (_loadingMind) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Soul.md — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _soulExpanded = !_soulExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.accentPrimary, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('soul.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _soulContent?.isNotEmpty == true ? '${_soulContent!.length} 字' : '空',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _soulExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_soulExpanded) ...[
                  const SizedBox(height: 8),
                  if (_editingSoul) ...[
                    TextField(
                      controller: _soulController,
                      maxLines: 15,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: '定义 Agent 的性格和核心行为...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _soulController.text = _soulContent ?? '';
                            setState(() => _editingSoul = false);
                          },
                          child: const Text('取消'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _savingSoul ? null : _saveSoulMd,
                          child: _savingSoul ? _miniSpinner() : const Text('保存'),
                        ),
                      ],
                    ),
                  ] else ...[
                    _codeBlock(_soulContent, '暂无内容，点击编辑按钮创建。'),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('编辑'),
                        onPressed: () => setState(() => _editingSoul = true),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // HEARTBEAT.md — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _heartbeatExpanded = !_heartbeatExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('HEARTBEAT.md', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _heartbeatContent?.isNotEmpty == true ? '${_heartbeatContent!.length} 字' : '空',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _heartbeatExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_heartbeatExpanded) ...[
                  const SizedBox(height: 8),
                  _codeBlock(_heartbeatContent, '暂无内容'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Memory Files — collapsible
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _memoryExpanded = !_memoryExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(Icons.memory, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('记忆文件', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '${_memoryFiles.length} 个文件',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _memoryExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textTertiary, size: 20,
                      ),
                    ],
                  ),
                ),
                if (_memoryExpanded) ...[
                  const SizedBox(height: 12),
                if (_memoryFiles.isEmpty)
                  const Text(
                    '暂无记忆文件。',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic),
                  )
                else
                  ..._memoryFiles.map((f) {
                    final file = f as Map<String, dynamic>;
                    final name = file['name'] as String? ?? '';
                    final size = file['size'] ?? 0;
                    final modified = file['modified'] ?? file['updated_at'];
                    return InkWell(
                      onTap: () => _readMemoryFile(name),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, color: AppColors.textTertiary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                            if (modified != null)
                              Text(_fmtRelative(modified), style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            const SizedBox(width: 8),
                            Text('$size 字节', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }),
                ], // end _memoryExpanded
              ],
            ),
          ),
        ],
      ),
    );
  }
}
