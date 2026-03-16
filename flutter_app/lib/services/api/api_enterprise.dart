part of 'api_service.dart';

// ─── Channel ──────────────────────────────────────────
extension ApiChannel on ApiService {
  Future<Map<String, dynamic>?> getChannel(String agentId) async {
    try {
      final r = await _apiDio.get('/agents/$agentId/channel');
      return r.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getChannelWebhookUrl(String agentId) async {
    try {
      final r = await _apiDio.get('/agents/$agentId/channel/webhook-url');
      return (r.data as Map<String, dynamic>)['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createChannel(String agentId, Map<String, dynamic> data) async {
    final r = await _apiDio.post('/agents/$agentId/channel', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateChannel(String agentId, Map<String, dynamic> data) async {
    // Backend uses POST with upsert logic (no PUT endpoint)
    final r = await _apiDio.post('/agents/$agentId/channel', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteChannel(String agentId) async {
    await _apiDio.delete('/agents/$agentId/channel');
  }
}

// ─── Enterprise ───────────────────────────────────────
extension ApiEnterprise on ApiService {
  Future<List<dynamic>> listLlmModels() async {
    final r = await _apiDio.get('/enterprise/llm-models');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTenantQuotas() async {
    final r = await _apiDio.get('/enterprise/tenant-quotas');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getNotificationBar() async {
    try {
      final r = await _apiDio.get('/enterprise/system-settings/notification_bar/public');
      return r.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Enterprise KB
  Future<List<dynamic>> listKbFiles({String path = ''}) async {
    final r = await _apiDio.get('/enterprise/knowledge-base/files', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> readKbFile(String path) async {
    final r = await _apiDio.get('/enterprise/knowledge-base/content', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeKbFile(String path, String content) async {
    await _apiDio.put('/enterprise/knowledge-base/content',
        queryParameters: {'path': path}, data: {'content': content});
  }

  Future<void> deleteKbFile(String path) async {
    await _apiDio.delete('/enterprise/knowledge-base/content', queryParameters: {'path': path});
  }

  Future<Map<String, dynamic>> uploadKbFile(List<int> bytes, String fileName,
      {String path = ''}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final r = await _apiDio.post('/enterprise/knowledge-base/upload',
        queryParameters: path.isNotEmpty ? {'sub_path': path} : null, data: formData);
    return r.data as Map<String, dynamic>;
  }
}

// ─── Org Structure ────────────────────────────────
extension ApiOrg on ApiService {
  Future<Map<String, dynamic>?> getSystemSetting(String key) async {
    try {
      final r = await _apiDio.get('/enterprise/system-settings/$key');
      return r.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSystemSetting(String key, dynamic value) async {
    await _apiDio.put('/enterprise/system-settings/$key', data: {'value': value});
  }

  Future<List<dynamic>> listOrgDepartments({String? tenantId}) async {
    final r = await _apiDio.get('/enterprise/org/departments',
        queryParameters: tenantId != null ? {'tenant_id': tenantId} : null);
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listOrgMembers({String? departmentId, String? search, String? tenantId}) async {
    final params = <String, dynamic>{};
    if (departmentId != null) params['department_id'] = departmentId;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tenantId != null) params['tenant_id'] = tenantId;
    final r = await _apiDio.get('/enterprise/org/members', queryParameters: params);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> syncOrg() async {
    final r = await _apiDio.post('/enterprise/org/sync');
    return r.data as Map<String, dynamic>;
  }
}

// ─── Invitation Codes ─────────────────────────────────
extension ApiInvitationCodes on ApiService {
  Future<Map<String, dynamic>> getInvitationSetting() async {
    final r = await _apiDio.get('/enterprise/system-settings/invitation_code_enabled');
    return r.data as Map<String, dynamic>;
  }

  Future<void> setInvitationSetting(bool enabled) async {
    await _apiDio.put('/enterprise/system-settings/invitation_code_enabled',
        data: {'value': {'enabled': enabled}});
  }

  Future<Map<String, dynamic>> listInvitationCodes({int page = 1, int pageSize = 20, String? search}) async {
    final params = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final r = await _apiDio.get('/enterprise/invitation-codes', queryParameters: params);
    return r.data as Map<String, dynamic>;
  }

  Future<void> createInvitationCodes(int count, int maxUses) async {
    await _apiDio.post('/enterprise/invitation-codes', data: {'count': count, 'max_uses': maxUses});
  }

  Future<void> deactivateInvitationCode(String id) async {
    await _apiDio.delete('/enterprise/invitation-codes/$id');
  }

  Future<String> exportInvitationCodes() async {
    final r = await _apiDio.get('/enterprise/invitation-codes/export',
        options: Options(responseType: ResponseType.plain));
    return r.data as String;
  }
}
