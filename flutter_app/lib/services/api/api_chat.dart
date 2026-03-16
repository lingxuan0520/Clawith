part of 'api_service.dart';

// ─── Sessions ─────────────────────────────────────────
extension ApiSessions on ApiService {
  Future<List<dynamic>> listSessions(String agentId, {String scope = 'mine'}) async {
    final r = await _apiDio.get('/agents/$agentId/sessions', queryParameters: {'scope': scope});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession(String agentId) async {
    final r = await _apiDio.post('/agents/$agentId/sessions', data: {});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionMessages(
    String agentId, String sessionId, {int limit = 50, String? before}
  ) async {
    final params = <String, dynamic>{'limit': limit};
    if (before != null) params['before'] = before;
    final r = await _apiDio.get('/agents/$agentId/sessions/$sessionId/messages',
        queryParameters: params);
    return r.data as Map<String, dynamic>;
  }
}

// ─── Chat ─────────────────────────────────────────────
extension ApiChat on ApiService {
  Future<List<dynamic>> getChatHistory(String agentId) async {
    final r = await _apiDio.get('/chat/$agentId/history');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadChatFile(String agentId, List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'agent_id': agentId,
    });
    final r = await _apiDio.post('/chat/upload', data: formData);
    return r.data as Map<String, dynamic>;
  }
}

// ─── Activity ─────────────────────────────────────────
extension ApiActivity on ApiService {
  Future<List<dynamic>> listActivity(String agentId, {int limit = 50}) async {
    final r = await _apiDio.get('/agents/$agentId/activity', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }
}

// ─── Messages ─────────────────────────────────────────
extension ApiMessages on ApiService {
  Future<List<dynamic>> getInbox({int limit = 50}) async {
    final r = await _apiDio.get('/messages/inbox', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final r = await _apiDio.get('/messages/unread-count');
    return r.data as Map<String, dynamic>;
  }

  Future<void> markRead(String messageId) async {
    await _apiDio.put('/messages/$messageId/read');
  }

  Future<void> markAllRead() async {
    await _apiDio.put('/messages/read-all');
  }
}
