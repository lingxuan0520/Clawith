import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  // Change this to your backend URL
  // For iOS simulator: http://localhost:8000
  // For Android emulator: http://10.0.2.2:8000
  // For web: '' (same origin, use proxy)
  // For production: https://your-server.com
  static String get baseUrl {
    if (kIsWeb) return '/api';
    // Default to localhost for development
    return 'http://47.251.71.144/api';
  }

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint(o.toString()),
      ));
    }
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Set the server base URL at runtime
  static void setBaseUrl(String url) {
    instance.dio.options.baseUrl = url;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired - clear and redirect to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
    handler.next(err);
  }
}
