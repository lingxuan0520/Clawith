import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../../core/network/api_client.dart';

part 'api_agents.dart';
part 'api_tasks.dart';
part 'api_files.dart';
part 'api_chat.dart';
part 'api_enterprise.dart';
part 'api_plaza.dart';
part 'api_tools.dart';
part 'api_billing.dart';

/// Shared Dio instance for all API extensions.
/// Accessible from part files (same library scope).
Dio get _apiDio => ApiClient.instance.dio;

/// API service layer — mirrors React services/api.ts
class ApiService {
  static ApiService? _inst;
  static ApiService get instance => _inst ??= ApiService._();
  ApiService._();

  @visibleForTesting
  static set testInstance(ApiService? instance) => _inst = instance;

  Dio get _dio => _apiDio;

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
}
