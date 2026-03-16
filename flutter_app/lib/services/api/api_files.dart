part of 'api_service.dart';

// ─── Files ────────────────────────────────────────────
extension ApiFiles on ApiService {
  Future<List<dynamic>> listFiles(String agentId, {String path = ''}) async {
    final r = await _apiDio.get('/agents/$agentId/files/', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> readFile(String agentId, String path) async {
    final r = await _apiDio.get('/agents/$agentId/files/content', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeFile(String agentId, String path, String content) async {
    await _apiDio.put('/agents/$agentId/files/content',
        queryParameters: {'path': path},
        data: {'content': content});
  }

  Future<void> deleteFile(String agentId, String path) async {
    await _apiDio.delete('/agents/$agentId/files/content', queryParameters: {'path': path});
  }

  Future<Map<String, dynamic>> importSkill(String agentId, String skillId) async {
    final r = await _apiDio.post('/agents/$agentId/files/import-skill',
        data: {'skill_id': skillId});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadFile(String agentId, String filePath, String fileName,
      {String path = 'workspace/knowledge_base'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final r = await _apiDio.post('/agents/$agentId/files/upload',
        queryParameters: {'path': path}, data: formData);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadFileBytes(String agentId, List<int> bytes, String fileName,
      {String path = 'workspace/knowledge_base'}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final r = await _apiDio.post('/agents/$agentId/files/upload',
        queryParameters: {'path': path}, data: formData);
    return r.data as Map<String, dynamic>;
  }
}

// ─── Skills ───────────────────────────────────────────
extension ApiSkills on ApiService {
  Future<List<dynamic>> listSkills() async {
    final r = await _apiDio.get('/skills/');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSkill(String id) async {
    final r = await _apiDio.get('/skills/$id');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createSkill(Map<String, dynamic> data) async {
    final r = await _apiDio.post('/skills/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSkill(String id, Map<String, dynamic> data) async {
    final r = await _apiDio.put('/skills/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteSkill(String id) async {
    await _apiDio.delete('/skills/$id');
  }

  Future<List<dynamic>> listSkillFiles({String path = ''}) async {
    final r = await _apiDio.get('/skills/browse/list', queryParameters: {'path': path});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> readSkillFile(String path) async {
    final r = await _apiDio.get('/skills/browse/read', queryParameters: {'path': path});
    return r.data as Map<String, dynamic>;
  }

  Future<void> writeSkillFile(String path, String content) async {
    await _apiDio.put('/skills/browse/write',
        queryParameters: {'path': path}, data: {'content': content});
  }

  Future<void> deleteSkillFile(String path) async {
    await _apiDio.delete('/skills/browse/delete', queryParameters: {'path': path});
  }
}
