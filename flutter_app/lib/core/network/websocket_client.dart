import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatMessage {
  final String role;
  final String content;
  final String? fileName;
  final List<ToolCallInfo>? toolCalls;
  final String? thinking;
  final String? imageUrl;

  ChatMessage({
    required this.role,
    required this.content,
    this.fileName,
    this.toolCalls,
    this.thinking,
    this.imageUrl,
  });

  ChatMessage copyWith({
    String? role,
    String? content,
    String? fileName,
    List<ToolCallInfo>? toolCalls,
    String? thinking,
    String? imageUrl,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      toolCalls: toolCalls ?? this.toolCalls,
      thinking: thinking ?? this.thinking,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class ToolCallInfo {
  final String name;
  final dynamic args;
  final String? result;
  ToolCallInfo({required this.name, this.args, this.result});
}

enum WsEventType { chunk, thinking, toolCall, done, legacy }

class WsEvent {
  final WsEventType type;
  final String? content;
  final String? toolName;
  final dynamic toolArgs;
  final String? toolResult;
  final String? role;

  WsEvent({
    required this.type,
    this.content,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.role,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'chunk':
        return WsEvent(type: WsEventType.chunk, content: json['content'] as String?);
      case 'thinking':
        return WsEvent(type: WsEventType.thinking, content: json['content'] as String?);
      case 'tool_call':
        return WsEvent(
          type: WsEventType.toolCall,
          toolName: json['name'] as String?,
          toolArgs: json['args'],
          toolResult: json['result'] as String?,
          content: json['status'] as String?,
        );
      case 'done':
        return WsEvent(type: WsEventType.done, content: json['content'] as String?);
      default:
        return WsEvent(
          type: WsEventType.legacy,
          role: json['role'] as String?,
          content: json['content'] as String?,
        );
    }
  }
}

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final String agentId;
  final String token;
  final String serverHost;
  Timer? _reconnectTimer;
  bool _disposed = false;

  final StreamController<WsEvent> _eventController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();

  Stream<WsEvent> get events => _eventController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  bool _connected = false;
  bool get isConnected => _connected;

  WebSocketClient({
    required this.agentId,
    required this.token,
    required this.serverHost,
  });

  void connect() {
    if (_disposed) return;
    _close();

    final scheme = serverHost.startsWith('https') ? 'wss' : 'ws';
    final host = serverHost.replaceFirst(RegExp(r'^https?://'), '');
    final wsUrl = '$scheme://$host/ws/chat/$agentId?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;
      _connectionController.add(true);

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _eventController.add(WsEvent.fromJson(json));
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onDone: () {
          _connected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
        onError: (e) {
          debugPrint('WS error: $e');
          _connected = false;
          _connectionController.add(false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('WS connect error: $e');
      _connected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connect);
  }

  void _close() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _close();
    _eventController.close();
    _connectionController.close();
  }
}
