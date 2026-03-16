part of 'api_service.dart';

// ─── Tasks ────────────────────────────────────────────
extension ApiTasks on ApiService {
  Future<List<dynamic>> listTasks(String agentId, {String? status, String? type}) async {
    final params = <String, String>{};
    if (status != null) params['status_filter'] = status;
    if (type != null) params['type_filter'] = type;
    final r = await _apiDio.get('/agents/$agentId/tasks/', queryParameters: params);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTask(String agentId, Map<String, dynamic> data) async {
    final r = await _apiDio.post('/agents/$agentId/tasks/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String agentId, String taskId, Map<String, dynamic> data) async {
    final r = await _apiDio.patch('/agents/$agentId/tasks/$taskId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTaskLogs(String agentId, String taskId) async {
    final r = await _apiDio.get('/agents/$agentId/tasks/$taskId/logs');
    return r.data as List<dynamic>;
  }

  Future<void> triggerTask(String agentId, String taskId) async {
    await _apiDio.post('/agents/$agentId/tasks/$taskId/trigger');
  }
}

// ─── Schedules ────────────────────────────────────────
extension ApiSchedules on ApiService {
  Future<List<dynamic>> listSchedules(String agentId) async {
    final r = await _apiDio.get('/agents/$agentId/schedules/');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSchedule(String agentId, Map<String, dynamic> data) async {
    final r = await _apiDio.post('/agents/$agentId/schedules/', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSchedule(String agentId, String scheduleId, Map<String, dynamic> data) async {
    final r = await _apiDio.patch('/agents/$agentId/schedules/$scheduleId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> triggerSchedule(String agentId, String scheduleId) async {
    await _apiDio.post('/agents/$agentId/schedules/$scheduleId/run');
  }

  Future<void> deleteSchedule(String agentId, String scheduleId) async {
    await _apiDio.delete('/agents/$agentId/schedules/$scheduleId');
  }

  Future<List<dynamic>> getScheduleHistory(String agentId, String scheduleId) async {
    final r = await _apiDio.get('/agents/$agentId/schedules/$scheduleId/history');
    return r.data as List<dynamic>;
  }
}

// ─── Triggers ─────────────────────────────────────────
extension ApiTriggers on ApiService {
  Future<List<dynamic>> listTriggers(String agentId) async {
    final r = await _apiDio.get('/agents/$agentId/triggers');
    return r.data as List<dynamic>;
  }

  Future<void> updateTrigger(String agentId, String triggerId, Map<String, dynamic> data) async {
    await _apiDio.patch('/agents/$agentId/triggers/$triggerId', data: data);
  }

  Future<void> deleteTrigger(String agentId, String triggerId) async {
    await _apiDio.delete('/agents/$agentId/triggers/$triggerId');
  }
}
