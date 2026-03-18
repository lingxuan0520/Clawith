import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Local file-based cache for chat messages.
/// Stores last N messages per agent so chat loads instantly.
class ChatCache {
  ChatCache._();
  static final ChatCache instance = ChatCache._();

  Directory? _cacheDir;
  // In-memory cache of last message per agent for chat list
  final Map<String, CachedLastMessage> _lastMessages = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/chat_cache');
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
    // Load last-message index
    await _loadLastMessageIndex();
    _initialized = true;
  }

  File _agentFile(String agentId) => File('${_cacheDir!.path}/$agentId.json');
  File get _indexFile => File('${_cacheDir!.path}/_last_messages.json');

  /// Save messages for an agent (keep last 50)
  Future<void> saveMessages(String agentId, List<Map<String, dynamic>> messages) async {
    await init();
    final toStore = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    await _agentFile(agentId).writeAsString(jsonEncode(toStore));

    // Update last message index
    if (messages.isNotEmpty) {
      final last = messages.last;
      _lastMessages[agentId] = CachedLastMessage(
        content: _extractPreview(last),
        role: last['role'] as String? ?? 'assistant',
        timestamp: DateTime.now().toIso8601String(),
      );
      await _saveLastMessageIndex();
    }
  }

  /// Load cached messages for an agent
  Future<List<Map<String, dynamic>>> loadMessages(String agentId) async {
    await init();
    final file = _agentFile(agentId);
    if (!file.existsSync()) return [];
    try {
      final data = jsonDecode(await file.readAsString()) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Get last message preview for an agent (for chat list)
  CachedLastMessage? getLastMessage(String agentId) {
    return _lastMessages[agentId];
  }

  /// Update last message for an agent (called when new message arrives via WS)
  void updateLastMessage(String agentId, String content, String role) {
    _lastMessages[agentId] = CachedLastMessage(
      content: content.length > 100 ? '${content.substring(0, 100)}...' : content,
      role: role,
      timestamp: DateTime.now().toIso8601String(),
    );
    _saveLastMessageIndex(); // fire-and-forget
  }

  String _extractPreview(Map<String, dynamic> msg) {
    final content = msg['content'] as String? ?? '';
    if (content.length > 100) return '${content.substring(0, 100)}...';
    return content;
  }

  Future<void> _loadLastMessageIndex() async {
    try {
      if (!_indexFile.existsSync()) return;
      final data = jsonDecode(await _indexFile.readAsString()) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final v = entry.value as Map<String, dynamic>;
        _lastMessages[entry.key] = CachedLastMessage(
          content: v['content'] as String? ?? '',
          role: v['role'] as String? ?? 'assistant',
          timestamp: v['timestamp'] as String? ?? '',
        );
      }
    } catch (_) {}
  }

  Future<void> _saveLastMessageIndex() async {
    try {
      final data = <String, dynamic>{};
      for (final entry in _lastMessages.entries) {
        data[entry.key] = {
          'content': entry.value.content,
          'role': entry.value.role,
          'timestamp': entry.value.timestamp,
        };
      }
      await _indexFile.writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}

class CachedLastMessage {
  final String content;
  final String role;
  final String timestamp;

  CachedLastMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });
}
