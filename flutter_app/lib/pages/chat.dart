import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../core/network/websocket_client.dart';
import '../core/network/api_client.dart';
import '../services/api.dart';
import '../stores/auth_store.dart';
import '../components/markdown_renderer.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String agentId;
  const ChatPage({super.key, required this.agentId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _historyMsgs = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  WebSocketClient? _ws;
  StreamSubscription? _eventSub;
  StreamSubscription? _connSub;
  StreamSubscription? _closeCodeSub;
  bool _connected = false;
  bool _uploading = false;
  bool _isReadOnly = false;
  bool _agentExpired = false;
  Map<String, dynamic>? _agent;
  _AttachedFile? _attachedFile;

  // Session state
  final List<Map<String, dynamic>> _sessions = [];
  final List<Map<String, dynamic>> _allSessions = [];
  Map<String, dynamic>? _activeSession;
  String _chatScope = 'mine';
  String _allUserFilter = '';
  bool _sessionsLoading = false;

  // Vision model support
  bool _supportsVision = false;

  // Streaming accumulators
  String _streamContent = '';
  String _thinkingContent = '';
  final List<ToolCallInfo> _pendingToolCalls = [];
  bool _waitingForResponse = false;

  // Smart scroll
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() { if (mounted) setState(() {}); });
    _scrollCtrl.addListener(_onScroll);
    _loadAgent();
    _loadSessions();
    _checkVisionSupport();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    final current = _scrollCtrl.offset;
    final isNearBottom = (maxExtent - current) < 150;
    if (_showScrollToBottom == isNearBottom) {
      setState(() => _showScrollToBottom = !isNearBottom);
    }
  }

  Future<void> _loadAgent() async {
    try {
      final agent = await ApiService.instance.getAgent(widget.agentId);
      if (mounted) setState(() => _agent = agent);
    } catch (_) {}
  }

  Future<void> _checkVisionSupport() async {
    try {
      final agent = _agent ?? await ApiService.instance.getAgent(widget.agentId);
      final primaryModelId = agent['primary_model_id'] as String?;
      if (primaryModelId == null) return;
      final models = await ApiService.instance.listLlmModels();
      if (!mounted) return;
      final supported = models.any((m) =>
          (m as Map<String, dynamic>)['id'] == primaryModelId &&
          (m['supports_vision'] as bool? ?? false));
      setState(() => _supportsVision = supported);
    } catch (_) {}
  }

  Future<void> _loadSessions({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() => _sessionsLoading = true);
    }
    try {
      final data = await ApiService.instance.listSessions(widget.agentId, scope: 'mine');
      if (!mounted) return;
      setState(() {
        _sessions
          ..clear()
          ..addAll(data.cast<Map<String, dynamic>>());
        _sessionsLoading = false;
      });
      // Auto-select first session on initial load
      if (!silent && _activeSession == null && _sessions.isNotEmpty) {
        await _selectSession(_sessions.first);
      }
    } catch (_) {
      if (mounted) setState(() => _sessionsLoading = false);
    }
  }

  Future<void> _loadAllSessions() async {
    try {
      final data = await ApiService.instance.listSessions(widget.agentId, scope: 'all');
      if (mounted) {
        setState(() {
          _allSessions
            ..clear()
            ..addAll(data.cast<Map<String, dynamic>>());
        });
      }
    } catch (_) {}
  }

  Future<void> _createSession() async {
    try {
      final newSess = await ApiService.instance.createSession(widget.agentId);
      if (!mounted) return;
      setState(() {
        _sessions.insert(0, newSess);
      });
      await _selectSession(newSess);
      _scaffoldKey.currentState?.closeEndDrawer();
    } catch (_) {}
  }

  Future<void> _selectSession(Map<String, dynamic> sess) async {
    setState(() {
      _messages.clear();
      _historyMsgs.clear();
      _activeSession = sess;
      _isReadOnly = false;
      _agentExpired = false;
    });

    try {
      final msgs = await ApiService.instance.getSessionMessages(
        widget.agentId, sess['id'] as String,
      );
      if (!mounted) return;

      final auth = ref.read(authProvider);
      final isAgentSession =
          sess['source_channel'] == 'agent' || sess['participant_type'] == 'agent';
      final isOwnSession =
          !isAgentSession && (sess['user_id'] as String?) == auth.userId;

      if (isOwnSession) {
        setState(() {
          _messages.addAll(msgs.map((m) => _parseHistoryMessage(m as Map<String, dynamic>)));
          _isReadOnly = false;
        });
        _reconnectWs();
      } else {
        setState(() {
          _historyMsgs.addAll(msgs.map((m) => _parseHistoryMessage(m as Map<String, dynamic>)));
          _isReadOnly = true;
        });
        _ws?.dispose();
        _ws = null;
        if (mounted) setState(() => _connected = false);
      }
    } catch (_) {
      // If loading messages fails, still connect WS for own sessions
      final auth = ref.read(authProvider);
      final isAgentSession =
          sess['source_channel'] == 'agent' || sess['participant_type'] == 'agent';
      final isOwnSession =
          !isAgentSession && (sess['user_id'] as String?) == auth.userId;
      if (isOwnSession) _reconnectWs();
    }
    _scrollToBottom(force: true);
  }

  ChatMessage _parseHistoryMessage(Map<String, dynamic> m) {
    final role = m['role'] as String? ?? 'assistant';
    final content = m['content'] as String? ?? '';

    if (role == 'tool_call') {
      return ChatMessage(
        role: 'assistant',
        content: '',
        toolCalls: [
          ToolCallInfo(
            name: m['toolName'] as String? ?? '',
            args: m['toolArgs'],
            result: m['toolResult'] as String?,
          ),
        ],
      );
    }

    // Parse file/image markers in user messages
    if (role == 'user') {
      final newFmt = RegExp(r'^\[file:([^\]]+)\]\n?').firstMatch(content);
      if (newFmt != null) {
        return ChatMessage(
          role: role,
          fileName: newFmt.group(1),
          content: content.substring(newFmt.end).trim(),
        );
      }
      final oldFmt = RegExp(r'^\[File: ([^\]]+)\]').firstMatch(content);
      if (oldFmt != null) {
        final qMatch = RegExp(r'\nQuestion: ([\s\S]+)$').firstMatch(content);
        return ChatMessage(
          role: role,
          fileName: oldFmt.group(1),
          content: qMatch?.group(1)?.trim() ?? '',
        );
      }
      // Feishu/Slack upload format
      final feishuFmt = RegExp(r'^\[文件已上传: (?:workspace/uploads/)?([^\]\n]+)\]').firstMatch(content);
      if (feishuFmt != null) {
        return ChatMessage(
          role: role,
          fileName: feishuFmt.group(1),
          content: content.substring(feishuFmt.end).trim(),
        );
      }
    }

    return ChatMessage(role: role, content: content);
  }

  void _reconnectWs() {
    _eventSub?.cancel();
    _connSub?.cancel();
    _closeCodeSub?.cancel();
    _ws?.dispose();
    _ws = null;

    final auth = ref.read(authProvider);
    if (auth.token == null) return;

    final serverHost = ApiClient.baseUrl.replaceAll('/api', '');
    _ws = WebSocketClient(
      agentId: widget.agentId,
      token: auth.token!,
      serverHost: serverHost,
      sessionId: _activeSession?['id'] as String?,
    );

    _connSub = _ws!.connectionState.listen((connected) {
      if (mounted) setState(() => _connected = connected);
    });
    _eventSub = _ws!.events.listen(_handleWsEvent);
    _closeCodeSub = _ws!.closeCodes.listen(_handleCloseCode);
    _ws!.connect();
  }

  void _handleCloseCode(int code) {
    if (!mounted) return;
    if (code == 4003) {
      setState(() => _agentExpired = true);
    } else if (code == 4002) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent 配置错误，请检查模型设置')),
      );
    }
  }

  void _handleWsEvent(WsEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case WsEventType.thinking:
          _waitingForResponse = false;

          _thinkingContent += event.content ?? '';
          _updateOrAddAssistant(content: _streamContent, thinking: _thinkingContent);
          break;
        case WsEventType.chunk:
          _waitingForResponse = false;

          _streamContent += event.content ?? '';
          _updateOrAddAssistant(content: _streamContent, thinking: _thinkingContent);
          break;
        case WsEventType.toolCall:
          if (event.content == 'done') {
            _pendingToolCalls.add(ToolCallInfo(
              name: event.toolName ?? '',
              args: event.toolArgs,
              result: event.toolResult,
            ));
          }
          break;
        case WsEventType.done:
          _waitingForResponse = false;
          final toolCalls = _pendingToolCalls.isNotEmpty
              ? List<ToolCallInfo>.from(_pendingToolCalls)
              : null;
          final thinking = _thinkingContent.isNotEmpty ? _thinkingContent : null;
          _pendingToolCalls.clear();
          _streamContent = '';
          _thinkingContent = '';
          if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
            _messages[_messages.length - 1] = ChatMessage(
              role: 'assistant',
              content: event.content ?? '',
              toolCalls: toolCalls,
              thinking: thinking,
            );
          } else {
            _messages.add(ChatMessage(
              role: 'assistant',
              content: event.content ?? '',
              toolCalls: toolCalls,
              thinking: thinking,
            ));
          }
          // Silently refresh session list to update last_message_at
          _loadSessions(silent: true);
          break;
        case WsEventType.error:
        case WsEventType.quotaExceeded:
          _waitingForResponse = false;
          final errMsg = event.content ?? '请求失败';
          // Dedup: don't add if last message is identical
          if (_messages.isEmpty || _messages.last.content != '⚠️ $errMsg') {
            _messages.add(ChatMessage(role: 'assistant', content: '⚠️ $errMsg'));
          }
          break;
        case WsEventType.triggerNotification:
          _messages.add(ChatMessage(role: 'assistant', content: event.content ?? ''));
          _loadSessions(silent: true);
          break;
        case WsEventType.legacy:
          _messages.add(ChatMessage(
            role: event.role ?? 'assistant',
            content: event.content ?? '',
          ));
          break;
      }
    });
    _scrollToBottom();
  }

  void _updateOrAddAssistant({required String content, String? thinking}) {
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _messages[_messages.length - 1] = _messages.last.copyWith(
        content: content,
        thinking: thinking,
      );
    } else {
      _messages.add(ChatMessage(role: 'assistant', content: content, thinking: thinking));
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final maxExtent = _scrollCtrl.position.maxScrollExtent;
      final current = _scrollCtrl.offset;
      final isNearBottom = (maxExtent - current) < 150;
      if (force || isNearBottom) {
        _scrollCtrl.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFileSelect() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      final data = await ApiService.instance.uploadChatFile(
        widget.agentId, file.bytes!.toList(), file.name,
      );
      if (mounted) {
        setState(() {
          _attachedFile = _AttachedFile(
            name: data['filename'] as String? ?? file.name,
            text: data['extracted_text'] as String? ?? '',
            path: data['workspace_path'] as String?,
            imageUrl: data['image_data_url'] as String?,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: ${_errMsg(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _sendMessage() {
    if (_ws == null || !_connected || _isReadOnly) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _attachedFile == null) return;

    _pendingToolCalls.clear();
    _streamContent = '';
    _thinkingContent = '';

    String userMsg = text;
    String contentForLLM = text;

    if (_attachedFile != null) {
      final af = _attachedFile!;
      if (af.imageUrl != null && _supportsVision) {
        // Vision model — embed image data for direct analysis
        contentForLLM = text.isNotEmpty
            ? '[image_data:${af.imageUrl}]\n$text'
            : '[image_data:${af.imageUrl}]\n请分析这张图片';
        if (userMsg.isEmpty) userMsg = '[图片] ${af.name}';
      } else if (af.imageUrl != null) {
        // Non-vision model — reference file path, let model use read_document tool
        final wsPath = af.path ?? '';
        contentForLLM = text.isNotEmpty
            ? '[图片文件已上传: ${af.name}，保存在 $wsPath]\n\n$text'
            : '[图片文件已上传: ${af.name}，保存在 $wsPath]\n请描述或处理这个图片文件。你可以使用 read_document 工具读取它。';
        if (userMsg.isEmpty) userMsg = '[图片] ${af.name}';
      } else {
        final wsPath = af.path ?? '';
        final codePath = wsPath.replaceFirst(RegExp(r'^workspace/'), '');
        final fileLoc = wsPath.isNotEmpty
            ? '\nFile location: $wsPath (for read_file/read_document tools)\nIn execute_code, use relative path: "$codePath"'
            : '';
        final fileContext = '[文件: ${af.name}]$fileLoc\n\n${af.text}';
        contentForLLM = text.isNotEmpty
            ? '$fileContext\n\n用户问题: $text'
            : '请阅读并分析以下文件内容:\n\n$fileContext';
        if (userMsg.isEmpty) userMsg = '[附件] ${af.name}';
      }
    }

    setState(() {
      _messages.add(ChatMessage(
        role: 'user',
        content: userMsg,
        fileName: _attachedFile?.name,
        imageUrl: _attachedFile?.imageUrl,
      ));
    });

    _ws!.send({
      'content': contentForLLM,
      'display_content': userMsg,
      'file_name': _attachedFile?.name ?? '',
    });

    _inputCtrl.clear();
    setState(() {
      _attachedFile = null;
      _waitingForResponse = true;
    });
    _scrollToBottom(force: true);
  }

  String _fileEmoji(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return '📄';
    if (['csv', 'xlsx', 'xls'].contains(ext)) return '📊';
    if (['docx', 'doc'].contains(ext)) return '📝';
    return '📎';
  }

  bool _isImageFile(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
  }

  String _formatSessionTime(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgPrimary,
      endDrawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        child: _buildSessionsPanel(),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.bgTertiary,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.smart_toy, size: 18, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _agent?['name'] as String? ?? '...',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _connected
                              ? AppColors.statusRunning
                              : AppColors.statusStopped,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _connected ? '已连接' : '未连接',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                      if (_activeSession != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _activeSession!['title'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, size: 20),
            tooltip: '会话列表',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: _agentExpired ? _buildExpiredBanner() : Column(
        children: [
          Expanded(
            child: _isReadOnly ? _buildHistoryView() : _buildChatView(),
          ),
          if (!_isReadOnly) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Agent 已过期，暂停服务',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '请在 Agent 设置中更新过期时间',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    if (_activeSession == null && !_sessionsLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              '开始与 ${_agent?['name'] ?? 'Agent'} 对话',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _createSession,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('新建会话'),
            ),
          ],
        ),
      );
    }

    return _messages.isEmpty && !_waitingForResponse
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  '开始与 ${_agent?['name'] ?? 'Agent'} 对话',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text('支持文本和文件上传',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          )
        : Stack(
            children: [
              ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_waitingForResponse ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length && _waitingForResponse) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessage(_messages[i]);
                },
              ),
              if (_showScrollToBottom)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: () => _scrollToBottom(force: true),
                    backgroundColor: AppColors.bgElevated,
                    foregroundColor: AppColors.textSecondary,
                    elevation: 2,
                    tooltip: '滚动到底部',
                    child: const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ),
            ],
          );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.bgTertiary,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Icon(Icons.smart_toy, size: 18, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.bgElevated,
          child: Row(
            children: [
              const Icon(Icons.visibility, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                '只读 · ${_activeSession?['username'] ?? '其他用户'}的会话',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Expanded(
          child: _historyMsgs.isEmpty
              ? const Center(
                  child: Text('暂无消息',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _historyMsgs.length,
                  itemBuilder: (context, i) => _buildMessage(_historyMsgs[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attached file preview
        if (_attachedFile != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.bgElevated,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                if (_attachedFile!.imageUrl != null)
                  Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.bgTertiary,
                    ),
                    child: const Icon(Icons.image, size: 18, color: AppColors.textTertiary),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.attach_file, size: 16, color: AppColors.textTertiary),
                  ),
                Expanded(
                  child: Text(_attachedFile!.name,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
                IconButton(
                  onPressed: () => setState(() => _attachedFile = null),
                  icon: const Icon(Icons.close, size: 14),
                  iconSize: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        // Input row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: !_connected || _uploading ? null : _handleFileSelect,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file, size: 20),
                color: AppColors.textTertiary,
                tooltip: '上传文件',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KeyboardListener(
                  focusNode: _inputFocus,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _sendMessage();
                    }
                  },
                  child: TextField(
                    controller: _inputCtrl,
                    enabled: _connected && !_isReadOnly,
                    decoration: InputDecoration(
                      hintText: _attachedFile != null
                          ? '询问关于 ${_attachedFile!.name}...'
                          : '输入消息...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _connected &&
                        !_isReadOnly &&
                        (_inputCtrl.text.trim().isNotEmpty || _attachedFile != null)
                    ? _sendMessage
                    : null,
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsPanel() {
    final displaySessions = _chatScope == 'mine'
        ? _sessions
        : (_allUserFilter.isEmpty
            ? _allSessions
            : _allSessions
                .where((s) =>
                    (s['username'] ?? s['user_id']) == _allUserFilter)
                .toList());

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('会话', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          // Scope tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildScopeTab('我的会话', 'mine'),
                const SizedBox(width: 4),
                _buildScopeTab('所有用户', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // New session button (mine only)
          if (_chatScope == 'mine')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _createSession,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('新建会话', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppColors.borderSubtle),
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          // User filter (all sessions)
          if (_chatScope == 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonFormField<String>(
                initialValue: _allUserFilter,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                dropdownColor: AppColors.bgElevated,
                items: [
                  const DropdownMenuItem(value: '', child: Text('所有用户')),
                  ...{for (final s in _allSessions) s['username'] ?? s['user_id']}
                      .where((u) => u != null)
                      .map((u) => DropdownMenuItem(value: u as String, child: Text(u))),
                ],
                onChanged: (v) => setState(() => _allUserFilter = v ?? ''),
              ),
            ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          // Session list
          Expanded(
            child: _sessionsLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPrimary),
                  )
                : displaySessions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _chatScope == 'mine' ? '暂无会话\n点击「新建会话」开始' : '暂无会话',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.6),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displaySessions.length,
                        itemBuilder: (ctx, i) => _buildSessionItem(displaySessions[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String label, String scope) {
    final isActive = _chatScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _chatScope = scope);
          if (scope == 'all') _loadAllSessions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.accentPrimary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> sess) {
    final isActive = _activeSession?['id'] == sess['id'];
    final title = sess['title'] as String? ?? '未命名会话';
    final channel = sess['source_channel'] as String?;
    final msgCount = sess['message_count'] as int? ?? 0;
    final timeStr = _formatSessionTime(
        sess['last_message_at'] as String? ?? sess['created_at'] as String?);

    final channelLabels = {'feishu': '飞书', 'discord': 'Discord', 'slack': 'Slack'};
    final chLabel = channelLabels[channel];

    return InkWell(
      onTap: () {
        _selectSession(sess);
        _scaffoldKey.currentState?.closeEndDrawer();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.accentPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          color: isActive ? AppColors.bgTertiary : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
                if (chLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(chLabel,
                        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (isActive && _connected)
                  Container(
                    width: 5, height: 5,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusRunning,
                    ),
                  ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
                if (msgCount > 0) ...[
                  const Spacer(),
                  Text(
                    '$msgCount',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final bubbleChildren = <Widget>[];

    // File attachment
    if (msg.fileName != null) {
      if (_isImageFile(msg.fileName!) && msg.imageUrl != null) {
        bubbleChildren.add(Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: msg.imageUrl!.startsWith('http')
              ? Image.network(
                  msg.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.broken_image, color: AppColors.textTertiary),
                  ),
                )
              : Image.memory(
                  base64Decode(msg.imageUrl!
                      .replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.broken_image, color: AppColors.textTertiary),
                  ),
                ),
        ));
      } else {
        final emoji = _fileEmoji(msg.fileName!);
        bubbleChildren.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: EdgeInsets.only(bottom: msg.content.isNotEmpty ? 4 : 0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  msg.fileName!,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ));
      }
    }

    // Thinking (assistant only)
    if (!isUser && msg.thinking != null && msg.thinking!.isNotEmpty) {
      bubbleChildren.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF9382DC).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9382DC).withValues(alpha: 0.15)),
        ),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💭 ', style: TextStyle(fontSize: 12)),
              Text('思考中',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9382DC))),
            ],
          ),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(msg.thinking!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
              ),
            ),
          ],
        ),
      ));
    }

    // Tool calls (assistant only)
    if (!isUser && msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
      bubbleChildren.add(Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.accentSubtle,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build, size: 13, color: AppColors.accentPrimary),
              const SizedBox(width: 4),
              Text(
                '${msg.toolCalls!.length} 个工具调用',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentPrimary),
              ),
            ],
          ),
          children: msg.toolCalls!.asMap().entries.map((entry) {
            final j = entry.key;
            final tc = entry.value;
            return Container(
              padding: EdgeInsets.only(bottom: j < msg.toolCalls!.length - 1 ? 6 : 0),
              margin: EdgeInsets.only(bottom: j < msg.toolCalls!.length - 1 ? 6 : 0),
              decoration: BoxDecoration(
                border: j < msg.toolCalls!.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.borderSubtle))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tc.name,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentPrimary)),
                  if (tc.args != null)
                    Text(
                      tc.args is String ? tc.args : jsonEncode(tc.args),
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textTertiary),
                    ),
                  if (tc.result != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        child: Text(tc.result!,
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.textSecondary)),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ));
    }

    // Content
    if (msg.content.isNotEmpty) {
      bubbleChildren.add(
        isUser
            ? Text(msg.content,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white))
            : MarkdownRenderer(data: msg.content),
      );
    }

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 3),
            Flexible(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bubbleChildren,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.bgTertiary,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.person, size: 18, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.bgTertiary,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(Icons.smart_toy, size: 18, color: AppColors.textTertiary),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 7,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bubbleChildren,
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _connSub?.cancel();
    _closeCodeSub?.cancel();
    _ws?.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

String _errMsg(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'] as String?;
      if (detail != null && detail.isNotEmpty) return detail;
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    final sc = e.response?.statusCode;
    return sc != null ? 'HTTP $sc' : '网络错误';
  }
  return e.toString();
}

class _AttachedFile {
  final String name;
  final String text;
  final String? path;
  final String? imageUrl;
  _AttachedFile({required this.name, required this.text, this.path, this.imageUrl});
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            double phase = (t - delay) % 1.0;
            if (phase < 0) phase += 1.0;
            final opacity = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textTertiary.withValues(alpha: 0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}
