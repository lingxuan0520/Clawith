import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../services/api.dart';
import '../stores/app_store.dart';
import '../stores/auth_store.dart';
import 'local_web_server.dart';

/// Virtual office — loads the agent-town Phaser game from bundled assets.
///
/// Connects to /ws/events for real-time agent status push notifications.
/// When the backend changes an agent's status (running → idle, etc.),
/// the WebView is updated immediately without polling.
class OfficeWebViewPage extends ConsumerStatefulWidget {
  const OfficeWebViewPage({super.key});

  @override
  ConsumerState<OfficeWebViewPage> createState() => _OfficeWebViewPageState();
}

class _OfficeWebViewPageState extends ConsumerState<OfficeWebViewPage> {
  final LocalWebServer _webServer = LocalWebServer();
  WebViewController? _controller;
  bool _loading = true;
  bool _pageLoaded = false;
  String? _error;

  // Events WebSocket for real-time agent status push
  WebSocketChannel? _eventsChannel;
  StreamSubscription? _eventsSub;
  Timer? _reconnectTimer;

  // Cache: agentId → seatId mapping (built on initial inject)
  final Map<String, String> _agentSeatMap = {};

  @override
  void initState() {
    super.initState();
    _startServerAndLoad();
  }

  @override
  void dispose() {
    _disconnectEvents();
    _webServer.stop();
    super.dispose();
  }

  // ── Events WebSocket ──────────────────────────────────────

  void _connectEvents() {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;

    _disconnectEvents();

    final serverHost = ApiClient.baseUrl.replaceAll('/api', '');
    final scheme = serverHost.startsWith('https') ? 'wss' : 'ws';
    final host = serverHost.replaceFirst(RegExp(r'^https?://'), '');
    final wsUrl = '$scheme://$host/ws/events?token=${auth.token}';

    debugPrint('[OfficeEvents] Connecting to $wsUrl');
    try {
      _eventsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _eventsSub = _eventsChannel!.stream.listen(
        _onEventMessage,
        onDone: () {
          debugPrint('[OfficeEvents] Disconnected');
          _scheduleReconnect();
        },
        onError: (e) {
          debugPrint('[OfficeEvents] Error: $e');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[OfficeEvents] Connect error: $e');
      _scheduleReconnect();
    }
  }

  void _disconnectEvents() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _eventsSub?.cancel();
    _eventsSub = null;
    _eventsChannel?.sink.close();
    _eventsChannel = null;
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _connectEvents();
    });
  }

  /// Handle real-time events from backend
  void _onEventMessage(dynamic raw) {
    if (!mounted || !_pageLoaded || _controller == null) return;
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'agent_status') {
        final agentId = data['agent_id'] as String?;
        final status = data['status'] as String?;
        if (agentId == null || status == null) return;

        final seatId = _agentSeatMap[agentId];
        if (seatId == null) {
          // Agent not in current seat map — do a full refresh
          _refreshAgentData();
          return;
        }

        debugPrint('[OfficeEvents] Agent $agentId → $status (seat: $seatId)');

        // Push single agent status update to WebView
        final update = jsonEncode({'status': status});
        _controller!.runJavaScript(
          'if(window.flutterBridge){window.flutterBridge.updateAgentStatus("$seatId",$update);}',
        );
      }
    } catch (e) {
      debugPrint('[OfficeEvents] Parse error: $e');
    }
  }

  // ── WebView setup ─────────────────────────────────────────

  Future<void> _startServerAndLoad() async {
    try {
      final baseUrl = await _webServer.start();
      if (!mounted) return;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setOnConsoleMessage((message) {
          debugPrint('[WebView JS] ${message.level.name}: ${message.message}');
        })
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: _onJsMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() {
                _pageLoaded = true;
                _loading = false;
              });
              _injectAgentData();
              _connectEvents();
            },
            onWebResourceError: (error) {
              if (!mounted) return;
              setState(() {
                _error = '虚拟办公室加载失败: ${error.description}';
                _loading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(baseUrl));

      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '无法启动虚拟办公室: $e';
        _loading = false;
      });
    }
  }

  /// Handle messages from the Phaser game via FlutterChannel
  void _onJsMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final agentId = data['agentId'] as String?;

      debugPrint('[OfficeWebView] JS message: type=$type agentId=$agentId');

      if (agentId == null || agentId.isEmpty) return;

      switch (type) {
        case 'chat':
          context.push('/agents/$agentId/chat');
          break;
        case 'detail':
          context.push('/agents/$agentId');
          break;
      }
    } catch (e) {
      debugPrint('[OfficeWebView] JS message parse error: $e');
    }
  }

  /// Inject agent data into the WebView after the page loads
  Future<void> _injectAgentData() async {
    if (_controller == null) return;
    try {
      final seatData = await _buildSeatData();
      if (!mounted || !_pageLoaded) return;

      final jsonStr = jsonEncode(seatData);
      // Wait for Phaser to discover seats from the Tiled map
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      await _controller!.runJavaScript(
        'if(window.flutterBridge){window.flutterBridge.initAgents($jsonStr);}',
      );
    } catch (e) {
      debugPrint('Failed to inject agent data: $e');
    }
  }

  /// Full refresh — re-fetch all agents and re-inject
  Future<void> _refreshAgentData() async {
    if (_controller == null || !_pageLoaded) return;
    try {
      final seatData = await _buildSeatData();
      if (!mounted) return;

      final jsonStr = jsonEncode(seatData);
      await _controller!.runJavaScript(
        'if(window.flutterBridge){window.flutterBridge.initAgents($jsonStr);}',
      );
      debugPrint('[OfficeWebView] Agent data refreshed');
    } catch (e) {
      debugPrint('Failed to refresh agent data: $e');
    }
  }

  /// Fetch agents from API and build seat data for the game
  Future<List<Map<String, dynamic>>> _buildSeatData() async {
    final agents = await ApiService.instance.listAgents();
    final seatData = <Map<String, dynamic>>[];
    _agentSeatMap.clear();

    for (int i = 0; i < agents.length; i++) {
      final a = agents[i] as Map<String, dynamic>;
      final agentId = a['id']?.toString() ?? '';
      final seatId = 'seat-$i';
      final status = a['status']?.toString() ?? 'stopped';
      final taskSnippet = status == 'running'
          ? (a['role_description']?.toString() ?? a['name']?.toString())
          : null;

      _agentSeatMap[agentId] = seatId;

      seatData.add({
        'seatId': seatId,
        'agentId': agentId,
        'label': a['name']?.toString() ?? 'Agent ${i + 1}',
        'status': status == 'running'
            ? 'running'
            : (status == 'idle' ? 'idle' : 'stopped'),
        'taskSnippet': taskSnippet,
      });
    }
    return seatData;
  }

  @override
  Widget build(BuildContext context) {
    // Also refresh on tab switch as a safety net
    ref.listen(officeVisitCountProvider, (_, __) {
      _refreshAgentData();
    });

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.statusError),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _loading = true;
                      _pageLoaded = false;
                      _controller = null;
                    });
                    _startServerAndLoad();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_loading)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accentPrimary),
                    const SizedBox(height: 16),
                    Text(
                      '正在进入虚拟办公室...',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
