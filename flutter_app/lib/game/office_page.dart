import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../services/api.dart';
import 'agent_npc.dart';
import 'office_map.dart';
import 'office_player.dart';

/// Virtual office — pixel-art top-down workspace where the user controls
/// a character and interacts with Agent NPCs sitting at desks.
class OfficePage extends ConsumerStatefulWidget {
  const OfficePage({super.key});

  @override
  ConsumerState<OfficePage> createState() => _OfficePageState();
}

class _OfficePageState extends ConsumerState<OfficePage> {
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;

  AgentNpc? _nearbyNpc;
  bool _panelOpen = false;
  Map<String, dynamic>? _panelAgent;

  // Created once after agents load — stable refs for BonfireWidget
  OfficePlayer? _player;
  List<AgentNpc>? _npcs;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await ApiService.instance.listAgents();
      if (!mounted) return;
      final agentList = List<Map<String, dynamic>>.from(agents);
      setState(() {
        _agents = agentList;
        _player = OfficePlayer(
          position: Vector2(16.0 * kRenderTileSize, 20.0 * kRenderTileSize),
          onInteract: _onInteract,
        );
        _npcs = _createNpcs(agentList);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AgentNpc> _createNpcs(List<Map<String, dynamic>> agents) {
    final positions = getAgentDeskPositions();
    final list = <AgentNpc>[];
    for (int i = 0; i < agents.length && i < positions.length; i++) {
      final a = agents[i];
      final p = positions[i];
      // Use role_description as task hint when running
      final status = a['status']?.toString();
      final taskHint = status == 'running'
          ? (a['role_description']?.toString() ?? a['name']?.toString())
          : null;
      list.add(AgentNpc(
        agentId: a['id']?.toString() ?? '',
        agentName: a['name']?.toString() ?? 'Agent',
        agentStatus: status,
        agentTask: taskHint,
        colorVariant: i % 16,
        position: Vector2(p[0] * kRenderTileSize, p[1] * kRenderTileSize),
        onPlayerContact: (npc) {
          if (mounted) setState(() => _nearbyNpc = npc);
        },
        onPlayerLeave: (npc) {
          if (_nearbyNpc?.agentId == npc.agentId && mounted) {
            setState(() => _nearbyNpc = null);
          }
        },
      ));
    }
    return list;
  }

  void _onInteract() {
    if (_nearbyNpc == null) return;
    final agent = _agents.firstWhere(
      (a) => a['id']?.toString() == _nearbyNpc!.agentId,
      orElse: () => {},
    );
    if (agent.isEmpty) return;
    setState(() {
      _panelAgent = agent;
      _panelOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _player == null || _npcs == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentPrimary),
              SizedBox(height: 16),
              Text(
                'Entering office...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ---- Bonfire game canvas (stable, created once) ----
          BonfireWidget(
            map: buildOfficeMap(),
            player: _player!,
            components: _npcs!,
            playerControllers: [
              Joystick(
                directional: JoystickDirectional(
                  size: 70,
                  color: const Color(0x885A96FF),
                  isFixed: true,
                  margin: const EdgeInsets.only(left: 40, bottom: 70),
                ),
                actions: [
                  JoystickAction(
                    actionId: 1,
                    size: 50,
                    color: const Color(0x885A96FF),
                    alignment: Alignment.bottomRight,
                    margin: const EdgeInsets.only(right: 48, bottom: 90),
                  ),
                ],
              ),
            ],
            cameraConfig: CameraConfig(
              zoom: 1.5,
              moveOnlyMapArea: true,
              startFollowPlayer: true,
            ),
            backgroundColor: const Color(0xFF101216),
          ),

          // ---- HUD overlay ----
          _buildTopHud(context),

          // ---- Interact prompt (shown when near NPC) ----
          if (_nearbyNpc != null && !_panelOpen) _buildInteractPrompt(),

          // ---- Agent panel (shown on interact) ----
          if (_panelOpen && _panelAgent != null) _buildAgentPanel(context),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HUD
  // ─────────────────────────────────────────────

  Widget _buildTopHud(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _HudButton(icon: Icons.arrow_back, onTap: () => context.pop()),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 14, color: AppColors.accentText),
                  SizedBox(width: 6),
                  Text(
                    'Virtual Office',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.statusRunning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_agents.length} agents',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Interact prompt
  // ─────────────────────────────────────────────

  Widget _buildInteractPrompt() {
    final name = _nearbyNpc!.agentName;
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _onInteract,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.accentPrimary, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 16, color: AppColors.accentText),
                const SizedBox(width: 8),
                Text(
                  'Talk to $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.touch_app,
                    size: 14, color: AppColors.accentText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Agent panel
  // ─────────────────────────────────────────────

  Widget _buildAgentPanel(BuildContext context) {
    final agent = _panelAgent!;
    final name = agent['name']?.toString() ?? 'Agent';
    final description = agent['description']?.toString() ?? '';
    final status = agent['status']?.toString() ?? 'stopped';
    final agentId = agent['id']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'running':
        statusColor = AppColors.statusRunning;
        statusLabel = 'Running';
        break;
      case 'idle':
        statusColor = AppColors.statusIdle;
        statusLabel = 'Idle';
        break;
      case 'error':
        statusColor = AppColors.statusError;
        statusLabel = 'Error';
        break;
      default:
        statusColor = AppColors.statusStopped;
        statusLabel = 'Stopped';
    }

    return GestureDetector(
      onTap: () => setState(() => _panelOpen = false),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withAlpha(80),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // absorb
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Agent info row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(Icons.smart_toy,
                          color: AppColors.accentPrimary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textTertiary),
                      onPressed: () =>
                          setState(() => _panelOpen = false),
                    ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _panelOpen = false);
                          context.push('/agents/$agentId/chat');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Profile'),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(
                              color: AppColors.borderDefault),
                        ),
                        onPressed: () {
                          setState(() => _panelOpen = false);
                          context.push('/agents/$agentId');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HUD button
// ─────────────────────────────────────────────

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HudButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
