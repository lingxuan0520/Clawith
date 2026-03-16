part of 'api_service.dart';

// ─── Tools ────────────────────────────────────────────
extension ApiTools on ApiService {
  Future<List<dynamic>> listTools() async {
    final r = await _apiDio.get('/tools/');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listAgentTools(String agentId) async {
    final r = await _apiDio.get('/tools/agents/$agentId');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> listAgentToolsWithConfig(String agentId) async {
    final r = await _apiDio.get('/tools/agents/$agentId/with-config');
    return r.data as List<dynamic>;
  }

  Future<void> toggleAgentTool(String agentId, String toolId, bool enabled) async {
    await _apiDio.put('/tools/agents/$agentId', data: [{'tool_id': toolId, 'enabled': enabled}]);
  }

  Future<Map<String, dynamic>> updateToolConfig(
      String agentId, String toolId, Map<String, dynamic> config) async {
    final r = await _apiDio.put('/tools/agents/$agentId/tool-config/$toolId', data: {'config': config});
    return r.data as Map<String, dynamic>;
  }
}

// ─── Relationships ────────────────────────────────────
extension ApiRelationships on ApiService {
  Future<List<dynamic>> getRelationships(String agentId) async {
    final r = await _apiDio.get('/agents/$agentId/relationships/');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getAgentRelationships(String agentId) async {
    final r = await _apiDio.get('/agents/$agentId/relationships/agents');
    return r.data as List<dynamic>;
  }

  Future<void> updateRelationships(String agentId, List<dynamic> data) async {
    await _apiDio.put('/agents/$agentId/relationships/', data: {'relationships': data});
  }

  Future<void> deleteRelationship(String agentId, String relId) async {
    await _apiDio.delete('/agents/$agentId/relationships/$relId');
  }

  Future<void> updateAgentRelationships(String agentId, List<dynamic> data) async {
    await _apiDio.put('/agents/$agentId/relationships/agents', data: {'relationships': data});
  }

  Future<void> deleteAgentRelationship(String agentId, String relId) async {
    await _apiDio.delete('/agents/$agentId/relationships/agents/$relId');
  }
}
