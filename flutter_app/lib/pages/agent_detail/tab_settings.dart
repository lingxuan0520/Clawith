part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 7 : Settings
// ═══════════════════════════════════════════════════════════

extension _SettingsTab on _AgentDetailPageState {
  Widget _buildSettingsTab(Map<String, dynamic> agent) {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Model Configuration ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(icon: Icons.settings, label: '模型配置'),
                const SizedBox(height: 16),
                _buildModelDropdown('主模型', _modelCtrl),
                const SizedBox(height: 12),
                _buildModelDropdown('备用模型', _fallbackModelCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxTokensCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Token 上限', hintText: '4096'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _temperatureCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '温度', hintText: '0.7'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contextWindowCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '上下文窗口', hintText: '100'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxToolRoundsCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '最大工具轮次', hintText: '50'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Token 限额', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dailyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '每日 Token 限额', hintText: '不限'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _monthlyTokenCtrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '每月 Token 限额', hintText: '不限'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingSettings ? null : _saveSettings,
                    child: _savingSettings ? _miniSpinner() : const Text('保存设置'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Heartbeat (Settings) ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('心跳', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('定时巡检广场、执行工作，会消耗 Token', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch(
                      value: agent['heartbeat_enabled'] == true,
                      activeColor: AppColors.accentPrimary,
                      onChanged: (v) async {
                        await _api.updateAgent(widget.agentId, {'heartbeat_enabled': v});
                        _fetchAgentSilent();
                      },
                    ),
                  ],
                ),
                if (agent['heartbeat_enabled'] == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('间隔', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _heartbeatIntervalCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('分钟', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('活跃时段', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _heartbeatActiveHoursCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            hintText: '09:00-18:00',
                            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final interval = int.tryParse(_heartbeatIntervalCtrl.text) ?? 120;
                        final clamped = interval < 1 ? 1 : interval;
                        _heartbeatIntervalCtrl.text = '$clamped';
                        final hours = _heartbeatActiveHoursCtrl.text.trim();
                        try {
                          await _api.updateAgent(widget.agentId, {
                            'heartbeat_interval_minutes': clamped,
                            'heartbeat_active_hours': hours,
                          });
                          _showSnack('心跳设置已保存');
                          _fetchAgentSilent();
                        } catch (e) {
                          _showSnack('保存失败: ${_errMsg(e)}');
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ),
                  if (agent['last_heartbeat_at'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '上次心跳: ${_formatDateTime(agent['last_heartbeat_at'] as String)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Channel Configuration ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_tethering, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('通道配置', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_channelConfig == null && !_showCreateChannel) ...[
                  const Text('未配置通道。', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('配置通道'),
                    onPressed: () => setState(() => _showCreateChannel = true),
                    style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
                  ),
                ] else if (_showCreateChannel) ...[
                  DropdownButtonFormField<String>(
                    value: _newChannelType,
                    decoration: const InputDecoration(labelText: '通道类型', isDense: true),
                    dropdownColor: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'feishu', child: Text('飞书')),
                      DropdownMenuItem(value: 'slack', child: Text('Slack')),
                      DropdownMenuItem(value: 'discord', child: Text('Discord')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _newChannelType = v); },
                  ),
                  const SizedBox(height: 8),
                  if (_newChannelType == 'feishu') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'App ID', isDense: true, hintText: 'cli_xxx...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'App Secret', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelEncryptKeyCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Encrypt Key (可选)', isDense: true),
                    ),
                  ] else if (_newChannelType == 'slack') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true, hintText: 'xoxb-...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Signing Secret', isDense: true),
                    ),
                  ] else if (_newChannelType == 'discord') ...[
                    TextField(
                      controller: _channelIdCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Application ID', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelTokenCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelPublicKeyCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Public Key', isDense: true),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => setState(() => _showCreateChannel = false), child: const Text('取消')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _createChannel, child: const Text('保存')),
                    ],
                  ),
                ] else ...[
                  _settingRow('类型', _channelConfig?['type']?.toString() ?? '-'),
                  _settingRow('状态', _channelConfig?['status']?.toString() ?? '-'),
                  _settingRow('Webhook URL', _channelConfig?['webhook_url']?.toString() ?? '-'),
                  if (_channelConfig?['bot_name'] != null)
                    _settingRow('机器人名称', _channelConfig?['bot_name']?.toString() ?? '-'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('编辑'),
                        onPressed: () => setState(() => _showCreateChannel = true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('删除通道', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                        onPressed: _deleteChannel,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Danger Zone ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('危险操作', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Agent 一旦删除将无法恢复，请谨慎操作。',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (!_showDeleteConfirm)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('删除智能体'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    onPressed: () => setState(() => _showDeleteConfirm = true),
                  )
                else
                  Row(
                    children: [
                      const Text('确定要删除吗？', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                        onPressed: _deleteAgent,
                        child: const Text('确认删除'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _showDeleteConfirm = false),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModelDropdown(String label, TextEditingController ctrl) {
    if (_llmModels.isNotEmpty) {
      final currentValue = ctrl.text;
      final hasMatch = _llmModels.any((m) {
        final model = m as Map<String, dynamic>;
        return model['id']?.toString() == currentValue;
      });
      return DropdownButtonFormField<String>(
        value: hasMatch ? currentValue : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        dropdownColor: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        hint: Text('未选择', style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        items: [
          const DropdownMenuItem(value: '', child: Text('不使用', style: TextStyle(color: AppColors.textTertiary))),
          ..._llmModels.map((m) {
            final model = m as Map<String, dynamic>;
            final id = model['id']?.toString() ?? '';
            final displayLabel = (model['label'] as String?)?.isNotEmpty == true
                ? model['label'] as String
                : model['model']?.toString() ?? id;
            final provider = model['provider']?.toString() ?? '';
            final modelName = model['model']?.toString() ?? '';
            final subtitle = provider.isNotEmpty ? ' ($provider/$modelName)' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$displayLabel$subtitle',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (v) => setState(() => ctrl.text = v ?? ''),
      );
    }
    // No models configured yet — show hint to go to enterprise settings
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(labelText: label, hintText: '请先在设置中配置模型'),
        ),
        const SizedBox(height: 4),
        const Text('提示：请先前往「设置 → 模型池」添加 LLM 模型',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _settingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(child: SelectableText(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
