part of 'agent_detail_page.dart';

// ═══════════════════════════════════════════════════════════
// TAB 7 : Settings
// ═══════════════════════════════════════════════════════════

extension _SettingsTab on _AgentDetailPageState {
  Widget _buildSettingsTab(Map<String, dynamic> agent) {
    final l = AppLocalizations.of(context)!;
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(icon: Icons.face, label: 'Avatar'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AvatarService.avatarCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final idx = i + 1;
                      final selected = _avatarIndex == idx;
                      return GestureDetector(
                        onTap: () async {
                          final newIdx = selected ? null : idx;
                          setState(() => _avatarIndex = newIdx);
                          if (newIdx != null) {
                            await AvatarService.instance.setAvatar(widget.agentId, newIdx);
                          } else {
                            await AvatarService.instance.removeAvatar(widget.agentId);
                          }
                        },
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? AppColors.accentPrimary : AppColors.borderSubtle,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              AvatarService.assetPath(idx),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Model Configuration ──
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(icon: Icons.settings, label: l.settingsModelConfig),
                const SizedBox(height: 16),
                _buildModelDropdown(l.settingsPrimaryModel, _modelCtrl),
                const SizedBox(height: 12),
                _buildModelDropdown(l.settingsFallbackModel, _fallbackModelCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxTokensCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.settingsMaxTokens, hintText: '4096'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _temperatureCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l.settingsTemperature, hintText: '0.7'),
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
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.settingsContextWindow, hintText: '100'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxToolRoundsCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.settingsMaxToolRounds, hintText: '50'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l.settingsTokenLimits, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dailyTokenCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.settingsDailyTokenLimit, hintText: l.settingsNoLimit),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _monthlyTokenCtrl,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.settingsMonthlyTokenLimit, hintText: l.settingsNoLimit),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _savingSettings ? null : _saveSettings,
                    child: _savingSettings ? _miniSpinner() : Text(l.settingsSaveSettings),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.settingsHeartbeat, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text(l.settingsHeartbeatDesc, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
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
                      Text(l.settingsInterval, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                      Text(l.settingsMinutes, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      const SizedBox(width: 8),
                      Text(l.settingsMinInterval(_minHeartbeatInterval),
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(l.settingsActiveHours, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _heartbeatActiveHoursCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
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
                          final updated = await _api.updateAgent(widget.agentId, {
                            'heartbeat_interval_minutes': clamped,
                            'heartbeat_active_hours': hours,
                          });
                          if (!mounted) return;
                          // Sync controllers with actual saved values (backend may clamp)
                          final savedInterval = updated['heartbeat_interval_minutes'] ?? clamped;
                          final savedHours = updated['heartbeat_active_hours'] ?? hours;
                          _heartbeatIntervalCtrl.text = '$savedInterval';
                          _heartbeatActiveHoursCtrl.text = '$savedHours';
                          if (savedInterval != clamped) {
                            _showSnack(l.settingsIntervalAdjusted(savedInterval as int));
                          } else {
                            _showSnack(l.settingsHeartbeatSaved);
                          }
                          _fetchAgentSilent();
                        } catch (e) {
                          if (!mounted) return;
                          _showSnack(l.settingsSaveFailed(_errMsg(e)));
                        }
                      },
                      child: Text(l.commonSave),
                    ),
                  ),
                  if (agent['last_heartbeat_at'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l.settingsLastHeartbeat(_formatDateTime(agent['last_heartbeat_at'] as String))}',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
                    Icon(Icons.wifi_tethering, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.settingsChannelConfig, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_channelConfig == null && !_showCreateChannel) ...[
                  Text(l.settingsNoChannel, style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l.settingsConfigChannel),
                    onPressed: () => setState(() => _showCreateChannel = true),
                    style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
                  ),
                ] else if (_showCreateChannel) ...[
                  DropdownButtonFormField<String>(
                    value: _newChannelType,
                    decoration: InputDecoration(labelText: l.settingsChannelType, isDense: true),
                    dropdownColor: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    items: [
                      DropdownMenuItem(value: 'feishu', child: Text(l.settingsFeishu)),
                      const DropdownMenuItem(value: 'slack', child: Text('Slack')),
                      const DropdownMenuItem(value: 'discord', child: Text('Discord')),
                    ],
                    onChanged: (v) { if (v != null) setState(() => _newChannelType = v); },
                  ),
                  const SizedBox(height: 8),
                  if (_newChannelType == 'feishu') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'App ID', isDense: true, hintText: 'cli_xxx...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'App Secret', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelEncryptKeyCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.settingsEncryptKey, isDense: true),
                    ),
                  ] else if (_newChannelType == 'slack') ...[
                    TextField(
                      controller: _channelTokenCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true, hintText: 'xoxb-...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelSecretCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Signing Secret', isDense: true),
                    ),
                  ] else if (_newChannelType == 'discord') ...[
                    TextField(
                      controller: _channelIdCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Application ID', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelTokenCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Bot Token', isDense: true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _channelPublicKeyCtrl,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Public Key', isDense: true),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => setState(() => _showCreateChannel = false), child: Text(l.commonCancel)),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _createChannel, child: Text(l.commonSave)),
                    ],
                  ),
                ] else ...[
                  _settingRow(l.settingsChannelTypeName, _channelConfig?['type']?.toString() ?? '-'),
                  _settingRow(l.settingsChannelStatus, _channelConfig?['status']?.toString() ?? '-'),
                  _settingRow('Webhook URL', _channelConfig?['webhook_url']?.toString() ?? '-'),
                  if (_channelConfig?['bot_name'] != null)
                    _settingRow(l.settingsBotName, _channelConfig?['bot_name']?.toString() ?? '-'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: Text(l.commonEdit),
                        onPressed: () => setState(() => _showCreateChannel = true),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: Text(l.settingsDeleteChannel, style: TextStyle(color: AppColors.error)),
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
                Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text(l.settingsDangerZone, style: const TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.settingsDangerHint,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (!_showDeleteConfirm)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: Text(l.settingsDeleteAgent),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    onPressed: () => setState(() => _showDeleteConfirm = true),
                  )
                else
                  Row(
                    children: [
                      Text(l.settingsDeleteAgentConfirm, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                        onPressed: _deleteAgent,
                        child: Text(l.settingsConfirmDelete),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _showDeleteConfirm = false),
                        child: Text(l.commonCancel),
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
    final l = AppLocalizations.of(context)!;
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
        style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        hint: Text(l.settingsNotSelected, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        items: [
          DropdownMenuItem(value: '', child: Text(l.settingsNotUsed, style: TextStyle(color: AppColors.textTertiary))),
          ..._llmModels.map((m) {
            final model = m as Map<String, dynamic>;
            final id = model['id']?.toString() ?? '';
            final displayLabel = (model['label'] as String?)?.isNotEmpty == true
                ? model['label'] as String
                : model['model']?.toString() ?? id;
            final tier = model['tier']?.toString() ?? 'standard';
            final tierIcon = tier == 'premium' ? '💰💰💰' : (tier == 'standard' ? '💰💰' : '💰');
            final outputPrice = model['cost_per_output_token_million'];
            final priceHint = outputPrice != null ? ' ~\$${(outputPrice as num).toStringAsFixed(1)}/1M' : '';
            return DropdownMenuItem(
              value: id,
              child: Text('$displayLabel  $tierIcon$priceHint',
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
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(labelText: label, hintText: l.settingsNoModelHint),
        ),
        const SizedBox(height: 4),
        Text(l.settingsModelTip,
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
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(child: SelectableText(value, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
