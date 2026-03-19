import 'package:shared_preferences/shared_preferences.dart';

/// Manages agent avatar selection. Stored locally via SharedPreferences.
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  static const int avatarCount = 9;
  static const String _prefix = 'agent_avatar_';

  /// Asset path for a given avatar index (1-based).
  static String assetPath(int index) => 'assets/avatars/avatar_$index.jpg';

  /// Get stored avatar index for an agent (1-based), or null if not set.
  Future<int?> getAvatar(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$agentId');
  }

  /// Set avatar index for an agent (1-based).
  Future<void> setAvatar(String agentId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$agentId', index);
  }

  /// Remove avatar for an agent.
  Future<void> removeAvatar(String agentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$agentId');
  }

  /// Load avatars for multiple agents at once. Returns {agentId: index}.
  Future<Map<String, int>> getAvatars(List<String> agentIds) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{};
    for (final id in agentIds) {
      final val = prefs.getInt('$_prefix$id');
      if (val != null) result[id] = val;
    }
    return result;
  }
}
