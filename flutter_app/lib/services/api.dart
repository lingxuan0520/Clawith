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

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async {
    final r = await _dio.patch('/auth/me', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/auth/me');
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

  Future<Map<String, dynamic>> updateTenant(String tenantId, Map<String, dynamic> data) async {
    final r = await _dio.put('/tenants/$tenantId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteTenant(String tenantId) async {
    await _dio.delete('/tenants/$tenantId');
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

  Future<void> triggerTask(String agentId, String taskId) async {
    await _dio.post('/agents/$agentId/tasks/$taskId/trigger');
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

  Future<Map<String, dynamic>> importSkill(String agentId, String skillId) async {
    final r = await _dio.post('/agents/$agentId/files/import-skill',
        queryParameters: {'skill_id': skillId});
    return r.data as Map<String, dynamic>;
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

  // ─── Sessions ─────────────────────────────────────────
  Future<List<dynamic>> listSessions(String agentId, {String scope = 'mine'}) async {
    final r = await _dio.get('/agents/$agentId/sessions', queryParameters: {'scope': scope});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession(String agentId) async {
    final r = await _dio.post('/agents/$agentId/sessions', data: {});
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSessionMessages(String agentId, String sessionId) async {
    final r = await _dio.get('/agents/$agentId/sessions/$sessionId/messages');
    return r.data as List<dynamic>;
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

  Future<String?> getChannelWebhookUrl(String agentId) async {
    try {
      final r = await _dio.get('/agents/$agentId/channel/webhook-url');
      return (r.data as Map<String, dynamic>)['url'] as String?;
    } catch (_) {
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

  Future<Map<String, dynamic>> readKbFile(String path) async {
    final r = await _dio.get('/enterprise/knowledge-base/content', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeKbFile(String path, String content) async {
    await _dio.put('/enterprise/knowledge-base/content',
        queryParameters: {'path': path}, data: {'content': content});
  }

  Future<void> deleteKbFile(String path) async {
    await _dio.delete('/enterprise/knowledge-base/content', queryParameters: {'path': path});
  }

  Future<Map<String, dynamic>> uploadKbFile(List<int> bytes, String fileName,
      {String path = ''}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final r = await _dio.post('/enterprise/knowledge-base/upload',
        queryParameters: path.isNotEmpty ? {'path': path} : null, data: formData);
    return r.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> updateSchedule(String agentId, String scheduleId, Map<String, dynamic> data) async {
    final r = await _dio.patch('/agents/$agentId/schedules/$scheduleId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> triggerSchedule(String agentId, String scheduleId) async {
    await _dio.post('/agents/$agentId/schedules/$scheduleId/run');
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

  Future<Map<String, dynamic>> getSkill(String id) async {
    final r = await _dio.get('/skills/$id');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> data) async {
    final r = await _dio.post('/skills/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSkill(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/skills/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteSkill(String id) async {
    await _dio.delete('/skills/$id');
  }

  Future<List<dynamic>> listSkillFiles({String path = ''}) async {
    final r = await _dio.get('/skills/browse/list', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> readSkillFile(String path) async {
    final r = await _dio.get('/skills/browse/read', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeSkillFile(String path, String content) async {
    await _dio.put('/skills/browse/write',
        queryParameters: {'path': path}, data: {'content': content});
  }

  Future<void> deleteSkillFile(String path) async {
    await _dio.delete('/skills/browse/delete', queryParameters: {'path': path});
  }

  // ─── Relationships ────────────────────────────────────
  Future<List<dynamic>> getRelationships(String agentId) async {
    final r = await _dio.get('/agents/$agentId/relationships/');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getAgentRelationships(String agentId) async {
    final r = await _dio.get('/agents/$agentId/relationships/agents');
    return r.data as List<dynamic>;
  }

  Future<void> updateRelationships(String agentId, List<dynamic> data) async {
    await _dio.put('/agents/$agentId/relationships/', data: data);
  }

  Future<void> deleteRelationship(String agentId, String relId) async {
    await _dio.delete('/agents/$agentId/relationships/$relId');
  }

  Future<void> updateAgentRelationships(String agentId, List<dynamic> data) async {
    await _dio.put('/agents/$agentId/relationships/agents', data: data);
  }

  Future<void> deleteAgentRelationship(String agentId, String relId) async {
    await _dio.delete('/agents/$agentId/relationships/agents/$relId');
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

  Future<List<dynamic>> listAgentToolsWithConfig(String agentId) async {
    final r = await _dio.get('/tools/agents/$agentId/with-config');
    return r.data as List<dynamic>;
  }

  Future<void> toggleAgentTool(String agentId, String toolId, bool enabled) async {
    await _dio.put('/tools/agents/$agentId/tools/$toolId', data: {'enabled': enabled});
  }

  Future<Map<String, dynamic>> updateToolConfig(
      String agentId, String toolId, Map<String, dynamic> config) async {
    final r = await _dio.put('/tools/agents/$agentId/tool-config/$toolId', data: config);
    return r.data as Map<String, dynamic>;
  }

  // ─── Org Structure ────────────────────────────────
  Future<Map<String, dynamic>?> getSystemSetting(String key) async {
    try {
      final r = await _dio.get('/enterprise/system-settings/$key');
      return r.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSystemSetting(String key, dynamic value) async {
    await _dio.put('/enterprise/system-settings/$key', data: {'value': value});
  }

  Future<List<dynamic>> listOrgDepartments({String? tenantId}) async {
    final r = await _dio.get('/enterprise/org/departments',
        queryParameters: tenantId != null ? {'tenant_id': tenantId} : null);
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listOrgMembers({String? departmentId, String? search, String? tenantId}) async {
    final params = <String, dynamic>{};
    if (departmentId != null) params['department_id'] = departmentId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tenantId != null) params['tenant_id'] = tenantId;
    final r = await _dio.get('/enterprise/org/members', queryParameters: params);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> syncOrg() async {
    final r = await _dio.post('/enterprise/org/sync');
    return r.data as Map<String, dynamic>;
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

  Future<String> exportInvitationCodes() async {
    final r = await _dio.get('/enterprise/invitation-codes/export',
        options: Options(responseType: ResponseType.plain));
    return r.data as String;
  }
}
