import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A fake [HttpClientAdapter] that returns pre-configured responses
/// based on URL path + method matching. Used in widget tests to
/// prevent real HTTP calls while still exercising extension methods
/// on [ApiService] that use [Dio] internally.
class FakeDioAdapter implements HttpClientAdapter {
  /// Map of "METHOD path" → response body.
  /// e.g. {"GET /auth/me": {"id": "u1", "name": "Test"}}
  final Map<String, Object> responses = {};

  /// Status codes per route. Defaults to 200 if not specified.
  final Map<String, int> statusCodes = {};

  /// Responses that throw DioException.
  final Set<String> errorRoutes = {};

  void addResponse(String method, String path, Object body, {int statusCode = 200}) {
    final key = '${method.toUpperCase()} $path';
    responses[key] = body;
    statusCodes[key] = statusCode;
  }

  void addError(String method, String path) {
    errorRoutes.add('${method.toUpperCase()} $path');
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final method = options.method.toUpperCase();
    final path = options.path.startsWith('http')
        ? Uri.parse(options.path).path.replaceFirst('/api', '')
        : options.path;

    final key = '$method $path';

    if (errorRoutes.contains(key)) {
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
        type: DioExceptionType.badResponse,
      );
    }

    // Try exact match first, then prefix match for dynamic routes
    Object? body = responses[key];
    int statusCode = statusCodes[key] ?? 200;

    if (body == null) {
      // Try prefix matching for dynamic path segments
      for (final entry in responses.entries) {
        final pattern = entry.key;
        final patternParts = pattern.split(' ');
        if (patternParts[0] != method) continue;
        final patternPath = patternParts[1];
        if (path.startsWith(patternPath) || _matchWildcard(patternPath, path)) {
          body = entry.value;
          statusCode = statusCodes[pattern] ?? 200;
          break;
        }
      }
    }

    // Default: return empty success
    body ??= {};

    final jsonStr = jsonEncode(body);
    return ResponseBody.fromString(jsonStr, statusCode, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  bool _matchWildcard(String pattern, String actual) {
    // Simple wildcard: /agents/*/tasks matches /agents/abc/tasks
    final patternParts = pattern.split('/');
    final actualParts = actual.split('/');
    if (patternParts.length != actualParts.length) return false;
    for (int i = 0; i < patternParts.length; i++) {
      if (patternParts[i] == '*') continue;
      if (patternParts[i] != actualParts[i]) return false;
    }
    return true;
  }

  @override
  void close({bool force = false}) {}
}
