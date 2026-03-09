import 'dart:async';
import 'package:flutter/material.dart';
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
  final List<ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  WebSocketClient? _ws;
  StreamSubscription? _eventSub;
  StreamSubscription? _connSub;
  bool _connected = false;
  bool _uploading = false;
  Map<String, dynamic>? _agent;
  _AttachedFile? _attachedFile;

  // Streaming accumulators
  String _streamContent = '';
  String _thinkingContent = '';
  final List<ToolCallInfo> _pendingToolCalls = [];

  @override
  void initState() {
    super.initState();
    _loadAgent();
    _loadHistory();
    _connectWs();
  }

  Future<void> _loadAgent() async {
    try {
      final agent = await ApiService.instance.getAgent(widget.agentId);
      if (mounted) setState(() => _agent = agent);
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ApiService.instance.getChatHistory(widget.agentId);
      if (!mounted) return;
      setState(() {
        _messages.addAll(history.map((m) {
          final msg = ChatMessage(
            role: (m as Map<String, dynamic>)['role'] as String? ?? 'assistant',
            content: m['content'] as String? ?? '',
          );
          return _parseMessage(msg);
        }));
      });
      _scrollToBottom();
    } catch (_) {}
  }

  ChatMessage _parseMessage(ChatMessage msg) {
    if (msg.role != 'user') return msg;
    final content = msg.content;
    // [file:name.pdf]\ncontent
    final newFmt = RegExp(r'^\[file:([^\]]+)\]\n?').firstMatch(content);
    if (newFmt != null) {
      return msg.copyWith(
        fileName: newFmt.group(1),
        content: content.substring(newFmt.end).trim(),
      );
    }
    // Old format: [File: name.pdf]
    final oldFmt = RegExp(r'^\[File: ([^\]]+)\]').firstMatch(content);
    if (oldFmt != null) {
      final qMatch = RegExp(r'\nQuestion: ([\s\S]+)$').firstMatch(content);
      return msg.copyWith(
        fileName: oldFmt.group(1),
        content: qMatch?.group(1)?.trim() ?? '',
      );
    }
    return msg;
  }

  void _connectWs() {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;

    final serverHost = ApiClient.baseUrl.replaceAll('/api', '');
    _ws = WebSocketClient(
      agentId: widget.agentId,
      token: auth.token!,
      serverHost: serverHost,
    );

    _connSub = _ws!.connectionState.listen((connected) {
      if (mounted) setState(() => _connected = connected);
    });

    _eventSub = _ws!.events.listen(_handleWsEvent);
    _ws!.connect();
  }

  void _handleWsEvent(WsEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event.type) {
        case WsEventType.thinking:
          _thinkingContent += event.content ?? '';
          _updateOrAddAssistant(content: _streamContent, thinking: _thinkingContent);
          break;
        case WsEventType.chunk:
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
          final toolCalls = _pendingToolCalls.isNotEmpty ? List<ToolCallInfo>.from(_pendingToolCalls) : null;
          final thinking = _thinkingContent.isNotEmpty ? _thinkingContent : null;
          _pendingToolCalls.clear();
          _streamContent = '';
          _thinkingContent = '';
          // Replace last assistant message with final
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
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
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _sendMessage() {
    if (_ws == null || !_connected) return;
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _attachedFile == null) return;

    _pendingToolCalls.clear();
    _streamContent = '';
    _thinkingContent = '';

    String userMsg = text;
    String contentForLLM = text;

    if (_attachedFile != null) {
      final af = _attachedFile!;
      if (af.imageUrl != null) {
        contentForLLM = text.isNotEmpty
            ? '[image_data:${af.imageUrl}]\n$text'
            : '[image_data:${af.imageUrl}]\nPlease analyze this image';
        if (userMsg.isEmpty) userMsg = '[Image] ${af.name}';
      } else {
        final wsPath = af.path ?? '';
        final codePath = wsPath.replaceFirst(RegExp(r'^workspace/'), '');
        final fileLoc = wsPath.isNotEmpty
            ? '\nFile location: $wsPath (for read_file/read_document tools)\nIn execute_code, use relative path: "$codePath"'
            : '';
        final fileContext = '[file:${af.name}]$fileLoc\n\n${af.text}';
        contentForLLM = text.isNotEmpty
            ? '$fileContext\n\nUser question: $text'
            : 'Please read and analyze the following file:\n\n$fileContext';
        if (userMsg.isEmpty) userMsg = '[Attachment] ${af.name}';
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
    setState(() => _attachedFile = null);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.bgTertiary,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.smart_toy, size: 20, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_agent?['name'] as String? ?? '...', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _connected ? AppColors.statusRunning : AppColors.statusStopped,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _connected ? 'Connected' : 'Disconnected',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text('Start a conversation with ${_agent?['name'] ?? 'Agent'}',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('Supports text and file uploads', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildMessage(_messages[i]),
                ),
        ),

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
                const Icon(Icons.attach_file, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(child: Text(_attachedFile!.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                IconButton(
                  onPressed: () => setState(() => _attachedFile = null),
                  icon: const Icon(Icons.close, size: 14),
                  iconSize: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),

        // Input area
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
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.attach_file, size: 20),
                color: AppColors.textTertiary,
                tooltip: 'Upload file',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  enabled: _connected,
                  decoration: InputDecoration(
                    hintText: _attachedFile != null
                        ? 'Ask about ${_attachedFile!.name}...'
                        : 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _connected && (_inputCtrl.text.trim().isNotEmpty || _attachedFile != null)
                    ? _sendMessage
                    : null,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';
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
            child: Icon(
              isUser ? Icons.person : Icons.smart_toy,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File attachment
                if (msg.fileName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(msg.fileName!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                // Thinking
                if (msg.thinking != null && msg.thinking!.isNotEmpty)
                  Container(
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
                      title: const Text('Thinking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9382DC))),
                      children: [
                        Text(msg.thinking!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
                      ],
                    ),
                  ),
                // Tool calls
                if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ExpansionTile(
                      dense: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      title: Text(
                        '${msg.toolCalls!.length} tool call${msg.toolCalls!.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accentPrimary),
                      ),
                      children: msg.toolCalls!.map((tc) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tc.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentPrimary)),
                            Text(
                              tc.args?.toString() ?? '',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textTertiary),
                            ),
                            if (tc.result != null)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                constraints: const BoxConstraints(maxHeight: 120),
                                child: SingleChildScrollView(
                                  child: Text(tc.result!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary)),
                                ),
                              ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                // Content
                if (msg.content.isNotEmpty)
                  isUser
                      ? Text(msg.content, style: const TextStyle(fontSize: 14, height: 1.6))
                      : MarkdownRenderer(data: msg.content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _connSub?.cancel();
    _ws?.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _AttachedFile {
  final String name;
  final String text;
  final String? path;
  final String? imageUrl;
  _AttachedFile({required this.name, required this.text, this.path, this.imageUrl});
}
