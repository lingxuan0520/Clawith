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

enum WsEventType {
  chunk,
  thinking,
  toolCall,
  done,
  legacy,
  error,
  quotaExceeded,
  triggerNotification,
}

class WsEvent {
  final WsEventType type;
  final String? content;
  final String? role;
  final String? toolName;
  final dynamic toolArgs;
  final String? toolResult;

  WsEvent({
    required this.type,
    this.content,
    this.role,
    this.toolName,
    this.toolArgs,
    this.toolResult,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String?) {
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
      case 'error':
        final msg = json['content'] as String? ??
            json['detail'] as String? ??
            json['message'] as String? ??
            '请求失败';
        return WsEvent(type: WsEventType.error, content: msg);
      case 'quota_exceeded':
        final msg = json['content'] as String? ?? '配额已用尽';
        return WsEvent(type: WsEventType.quotaExceeded, content: msg);
      case 'trigger_notification':
        return WsEvent(type: WsEventType.triggerNotification, content: json['content'] as String?);
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
  final String? sessionId;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _permanentError = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _maxReconnectDelaySec = 30;

  final StreamController<WsEvent> _eventController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();
  final StreamController<int> _closeCodeController = StreamController.broadcast();

  Stream<WsEvent> get events => _eventController.stream;
  Stream<bool> get connectionState => _connectionController.stream;
  Stream<int> get closeCodes => _closeCodeController.stream;
  bool _connected = false;
  bool get isConnected => _connected;

  WebSocketClient({
    required this.agentId,
    required this.token,
    required this.serverHost,
    this.sessionId,
  });

  void connect() {
    if (_disposed || _permanentError) return;
    _close();

    final scheme = serverHost.startsWith('https') ? 'wss' : 'ws';
    final host = serverHost.replaceFirst(RegExp(r'^https?://'), '');
    final sessionParam = sessionId != null ? '&session_id=$sessionId' : '';
    final wsUrl = '$scheme://$host/ws/chat/$agentId?token=$token$sessionParam';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;
      _reconnectAttempts = 0;
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
          final code = _channel?.closeCode;
          _connected = false;
          _connectionController.add(false);
          if (code == 4002 || code == 4003) {
            _permanentError = true;
            _closeCodeController.add(code!);
          } else if (!_disposed) {
            _scheduleReconnect();
          }
        },
        onError: (e) {
          debugPrint('WS error: $e');
          _connected = false;
          _connectionController.add(false);
          if (!_disposed && !_permanentError) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      debugPrint('WS connect error: $e');
      _connected = false;
      _connectionController.add(false);
      if (!_disposed && !_permanentError) {
        _scheduleReconnect();
      }
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _permanentError) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WS max reconnect attempts reached ($_maxReconnectAttempts)');
      return;
    }
    _reconnectTimer?.cancel();
    final delaySec = (2 << _reconnectAttempts).clamp(2, _maxReconnectDelaySec);
    _reconnectAttempts++;
    debugPrint('WS reconnecting in ${delaySec}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delaySec), connect);
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
    _closeCodeController.close();
  }
}
