import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

/// API service layer — mirrors React services/api.ts
class ApiService {
  static ApiService? _inst;
  static ApiService get instance => _inst ??= ApiService._();
  ApiService._();

  Dio get _dio => ApiClient.instance.dio;

  // ─── Auth ─────────────────────────────────────────────
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final r = await _dio.post('/auth/register', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final r = await _dio.post('/auth/login', data: {'username': username, 'password': password});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final r = await _dio.get('/auth/me');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRegistrationConfig() async {
    final r = await _dio.get('/auth/registration-config');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginWithFirebase(String idToken) async {
    final r = await _dio.post('/auth/firebase', data: {'id_token': idToken});
    return r.data as Map<String, dynamic>;
  }

  // ─── Tenants ──────────────────────────────────────────
  Future<List<dynamic>> listPublicTenants() async {
    final r = await _dio.get('/tenants/public/list');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listTenants() async {
    final r = await _dio.get('/tenants/');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTenant(Map<String, dynamic> data) async {
    final r = await _dio.post('/tenants/', data: data);
    return r.data as Map<String, dynamic>;
  }

  // ─── Agents ───────────────────────────────────────────
  Future<List<dynamic>> listAgents({String? tenantId}) async {
    final r = await _dio.get('/agents/', queryParameters: tenantId != null ? {'tenant_id': tenantId} : null);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAgent(String id) async {
    final r = await _dio.get('/agents/$id');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> data) async {
    final r = await _dio.post('/agents/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAgent(String id, Map<String, dynamic> data) async {
    final r = await _dio.patch('/agents/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteAgent(String id) async {
    await _dio.delete('/agents/$id');
  }

  Future<Map<String, dynamic>> startAgent(String id) async {
    final r = await _dio.post('/agents/$id/start');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stopAgent(String id) async {
    final r = await _dio.post('/agents/$id/stop');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAgentMetrics(String id) async {
    final r = await _dio.get('/agents/$id/metrics');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCollaborators(String id) async {
    final r = await _dio.get('/agents/$id/collaborators');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getTemplates() async {
    final r = await _dio.get('/agents/templates');
    return r.data as List<dynamic>;
  }

  // ─── Tasks ────────────────────────────────────────────
  Future<List<dynamic>> listTasks(String agentId, {String? status, String? type}) async {
    final params = <String, String>{};
    if (status != null) params['status_filter'] = status;
    if (type != null) params['type_filter'] = type;
    final r = await _dio.get('/agents/$agentId/tasks/', queryParameters: params);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTask(String agentId, Map<String, dynamic> data) async {
    final r = await _dio.post('/agents/$agentId/tasks/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String agentId, String taskId, Map<String, dynamic> data) async {
    final r = await _dio.patch('/agents/$agentId/tasks/$taskId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTaskLogs(String agentId, String taskId) async {
    final r = await _dio.get('/agents/$agentId/tasks/$taskId/logs');
    return r.data as List<dynamic>;
  }

  // ─── Files ────────────────────────────────────────────
  Future<List<dynamic>> listFiles(String agentId, {String path = ''}) async {
    final r = await _dio.get('/agents/$agentId/files/', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> readFile(String agentId, String path) async {
    final r = await _dio.get('/agents/$agentId/files/content', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeFile(String agentId, String path, String content) async {
    await _dio.put('/agents/$agentId/files/content',
        queryParameters: {'path': path},
        data: {'content': content});
  }

  Future<void> deleteFile(String agentId, String path) async {
    await _dio.delete('/agents/$agentId/files/content', queryParameters: {'path': path});
  }

  Future<Map<String, dynamic>> uploadFile(String agentId, String filePath, String fileName,
      {String path = 'workspace/knowledge_base'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final r = await _dio.post('/agents/$agentId/files/upload',
        queryParameters: {'path': path}, data: formData);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadFileBytes(String agentId, List<int> bytes, String fileName,
      {String path = 'workspace/knowledge_base'}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final r = await _dio.post('/agents/$agentId/files/upload',
        queryParameters: {'path': path}, data: formData);
    return r.data as Map<String, dynamic>;
  }

  // ─── Chat ─────────────────────────────────────────────
  Future<List<dynamic>> getChatHistory(String agentId) async {
    final r = await _dio.get('/chat/$agentId/history');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadChatFile(String agentId, List<int> bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'agent_id': agentId,
    });
    final r = await _dio.post('/chat/upload', data: formData);
    return r.data as Map<String, dynamic>;
  }

  // ─── Channel ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getChannel(String agentId) async {
    try {
      final r = await _dio.get('/agents/$agentId/channel');
      return r.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createChannel(String agentId, Map<String, dynamic> data) async {
    final r = await _dio.post('/agents/$agentId/channel', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateChannel(String agentId, Map<String, dynamic> data) async {
    final r = await _dio.put('/agents/$agentId/channel', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteChannel(String agentId) async {
    await _dio.delete('/agents/$agentId/channel');
  }

  // ─── Enterprise ───────────────────────────────────────
  Future<List<dynamic>> listLlmModels() async {
    final r = await _dio.get('/enterprise/llm-models');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getNotificationBar() async {
    try {
      final r = await _dio.get('/enterprise/system-settings/notification_bar/public');
      return r.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Enterprise KB
  Future<List<dynamic>> listKbFiles({String path = ''}) async {
    final r = await _dio.get('/enterprise/knowledge-base/files', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  // ─── Activity ─────────────────────────────────────────
  Future<List<dynamic>> listActivity(String agentId, {int limit = 50}) async {
    final r = await _dio.get('/agents/$agentId/activity', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }

  // ─── Messages ─────────────────────────────────────────
  Future<List<dynamic>> getInbox({int limit = 50}) async {
    final r = await _dio.get('/messages/inbox', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    final r = await _dio.get('/messages/unread-count');
    return r.data as Map<String, dynamic>;
  }

  Future<void> markRead(String messageId) async {
    await _dio.put('/messages/$messageId/read');
  }

  Future<void> markAllRead() async {
    await _dio.put('/messages/read-all');
  }

  // ─── Schedules ────────────────────────────────────────
  Future<List<dynamic>> listSchedules(String agentId) async {
    final r = await _dio.get('/agents/$agentId/schedules/');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSchedule(String agentId, Map<String, dynamic> data) async {
    final r = await _dio.post('/agents/$agentId/schedules/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteSchedule(String agentId, String scheduleId) async {
    await _dio.delete('/agents/$agentId/schedules/$scheduleId');
  }

  Future<List<dynamic>> getScheduleHistory(String agentId, String scheduleId) async {
    final r = await _dio.get('/agents/$agentId/schedules/$scheduleId/history');
    return r.data as List<dynamic>;
  }

  // ─── Triggers ─────────────────────────────────────────
  Future<List<dynamic>> listTriggers(String agentId) async {
    final r = await _dio.get('/agents/$agentId/triggers');
    return r.data as List<dynamic>;
  }

  Future<void> updateTrigger(String agentId, String triggerId, Map<String, dynamic> data) async {
    await _dio.patch('/agents/$agentId/triggers/$triggerId', data: data);
  }

  Future<void> deleteTrigger(String agentId, String triggerId) async {
    await _dio.delete('/agents/$agentId/triggers/$triggerId');
  }

  // ─── Skills ───────────────────────────────────────────
  Future<List<dynamic>> listSkills() async {
    final r = await _dio.get('/skills/');
    return r.data as List<dynamic>;
  }

  // ─── Plaza ────────────────────────────────────────────
  Future<List<dynamic>> getPlazaPosts({int limit = 50}) async {
    final r = await _dio.get('/plaza/posts', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPlazaStats() async {
    final r = await _dio.get('/plaza/stats');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPlazaPost(String postId) async {
    final r = await _dio.get('/plaza/posts/$postId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPlazaPost(Map<String, dynamic> data) async {
    final r = await _dio.post('/plaza/posts', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> likePlazaPost(String postId, String authorId) async {
    await _dio.post('/plaza/posts/$postId/like',
        queryParameters: {'author_id': authorId, 'author_type': 'human'});
  }

  Future<Map<String, dynamic>> addPlazaComment(String postId, Map<String, dynamic> data) async {
    final r = await _dio.post('/plaza/posts/$postId/comments', data: data);
    return r.data as Map<String, dynamic>;
  }

  // ─── Tools ────────────────────────────────────────────
  Future<List<dynamic>> listTools() async {
    final r = await _dio.get('/tools/');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listAgentTools(String agentId) async {
    final r = await _dio.get('/tools/agents/$agentId/tools');
    return r.data as List<dynamic>;
  }

  Future<void> toggleAgentTool(String agentId, String toolId, bool enabled) async {
    await _dio.put('/tools/agents/$agentId/tools/$toolId', data: {'enabled': enabled});
  }

  // ─── Invitation Codes ─────────────────────────────────
  Future<Map<String, dynamic>> getInvitationSetting() async {
    final r = await _dio.get('/enterprise/system-settings/invitation_code_enabled');
    return r.data as Map<String, dynamic>;
  }

  Future<void> setInvitationSetting(bool enabled) async {
    await _dio.put('/enterprise/system-settings/invitation_code_enabled',
        data: {'value': {'enabled': enabled}});
  }

  Future<Map<String, dynamic>> listInvitationCodes({int page = 1, int pageSize = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final r = await _dio.get('/enterprise/invitation-codes', queryParameters: params);
    return r.data as Map<String, dynamic>;
  }

  Future<void> createInvitationCodes(int count, int maxUses) async {
    await _dio.post('/enterprise/invitation-codes', data: {'count': count, 'max_uses': maxUses});
  }

  Future<void> deactivateInvitationCode(String id) async {
    await _dio.delete('/enterprise/invitation-codes/$id');
  }
}
