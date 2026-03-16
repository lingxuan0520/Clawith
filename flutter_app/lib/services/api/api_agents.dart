part of 'api_service.dart';

// ─── Agents ───────────────────────────────────────────
extension ApiAgents on ApiService {
  Future<List<dynamic>> listAgents({String? tenantId}) async {
    final r = await _apiDio.get('/agents/', queryParameters: tenantId != null ? {'tenant_id': tenantId} : null);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAgent(String id) async {
    final r = await _apiDio.get('/agents/$id');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> data) async {
    final r = await _apiDio.post('/agents/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAgent(String id, Map<String, dynamic> data) async {
    final r = await _apiDio.patch('/agents/$id', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteAgent(String id) async {
    await _apiDio.delete('/agents/$id');
  }

  Future<Map<String, dynamic>> startAgent(String id) async {
    final r = await _apiDio.post('/agents/$id/start');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> stopAgent(String id) async {
    final r = await _apiDio.post('/agents/$id/stop');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAgentMetrics(String id) async {
    final r = await _apiDio.get('/agents/$id/metrics');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getCollaborators(String id) async {
    final r = await _apiDio.get('/agents/$id/collaborators');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getTemplates() async {
    final r = await _apiDio.get('/agents/templates');
    return r.data as List<dynamic>;
  }
}
