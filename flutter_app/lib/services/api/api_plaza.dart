part of 'api_service.dart';

// ─── Plaza ────────────────────────────────────────────
extension ApiPlaza on ApiService {
  Future<List<dynamic>> getPlazaPosts({int limit = 50}) async {
    final r = await _apiDio.get('/plaza/posts', queryParameters: {'limit': limit});
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPlazaStats() async {
    final r = await _apiDio.get('/plaza/stats');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPlazaPost(String postId) async {
    final r = await _apiDio.get('/plaza/posts/$postId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPlazaPost(Map<String, dynamic> data) async {
    final r = await _apiDio.post('/plaza/posts', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> likePlazaPost(String postId, String authorId) async {
    await _apiDio.post('/plaza/posts/$postId/like',
        queryParameters: {'author_id': authorId, 'author_type': 'human'});
  }

  Future<Map<String, dynamic>> addPlazaComment(String postId, Map<String, dynamic> data) async {
    final r = await _apiDio.post('/plaza/posts/$postId/comments', data: data);
    return r.data as Map<String, dynamic>;
  }
}
