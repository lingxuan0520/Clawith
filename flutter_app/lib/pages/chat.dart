import 'dart:async';
import 'dart:convert';
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
  final List<ChatMessage> _messages = [];
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
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
    // Rebuild when text changes so the Send button enables/disables correctly
    _inputCtrl.addListener(() { if (mounted) setState(() {}); });
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
          SnackBar(content: Text('上传失败: $e')),
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
            : '[image_data:${af.imageUrl}]\n请分析这张图片';
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
    setState(() => _attachedFile = null);
    _scrollToBottom();
  }

  /// Get file type emoji matching React implementation
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
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
                  Text(_agent?['name'] as String? ?? '...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _connected ? AppColors.statusRunning : AppColors.statusStopped,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _connected ? '已连接' : '未连接',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text('开始与 ${_agent?['name'] ?? 'Agent'} 对话',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('支持文本和文件上传', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
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
                    enabled: _connected,
                    focusNode: FocusNode(),
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
                onPressed: _connected && (_inputCtrl.text.trim().isNotEmpty || _attachedFile != null)
                    ? _sendMessage
                    : null,
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == 'user';

    // Build bubble content
    final bubbleChildren = <Widget>[];

    // File attachment with emoji icons (matching React)
    if (msg.fileName != null) {
      if (_isImageFile(msg.fileName!) && msg.imageUrl != null) {
        // Image preview
        bubbleChildren.add(Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            base64Decode(msg.imageUrl!.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.broken_image, color: AppColors.textTertiary),
            ),
          ),
        ));
      } else {
        // File badge with type emoji
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

    // Thinking (only for assistant)
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
              Text('思考中', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9382DC))),
            ],
          ),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(msg.thinking!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6)),
              ),
            ),
          ],
        ),
      ));
    }

    // Tool calls (only for assistant)
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accentPrimary),
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
                  Text(tc.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentPrimary)),
                  if (tc.args != null)
                    Text(
                      tc.args is String ? tc.args : jsonEncode(tc.args),
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
            );
          }).toList(),
        ),
      ));
    }

    // Content
    if (msg.content.isNotEmpty) {
      bubbleChildren.add(
        isUser
            ? Text(msg.content, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white))
            : MarkdownRenderer(data: msg.content),
      );
    }

    // Build the full message row
    if (isUser) {
      // User: right-aligned, accent background, avatar on right
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
      // Assistant: left-aligned, elevated background, avatar on left
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
    _ws?.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
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
