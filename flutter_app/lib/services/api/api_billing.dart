part of 'api_service.dart';

// ─── Billing ─────────────────────────────────────────
extension ApiBilling on ApiService {
  Future<Map<String, dynamic>> getBillingBalance() async {
    final r = await _apiDio.get('/billing/balance');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getBillingUsage({int days = 30, String? agentId}) async {
    final params = <String, dynamic>{'days': days};
    if (agentId != null) params['agent_id'] = agentId;
    final r = await _apiDio.get('/billing/usage', queryParameters: params);
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getBillingModels() async {
    final r = await _apiDio.get('/billing/models');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addBillingCredits(int amountCents) async {
    final r = await _apiDio.post('/billing/add-credits', data: {'amount_cents': amountCents});
    return r.data as Map<String, dynamic>;
  }
}
