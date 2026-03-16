import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stores/auth_store.dart';
import '../../services/api.dart';
import '../../core/theme/app_theme.dart';
import '../../core/app_lifecycle.dart';
import '../../components/initial_avatar.dart';
import 'plaza_rich_text.dart';

class PlazaPage extends ConsumerStatefulWidget {
  const PlazaPage({super.key});
  @override
  ConsumerState<PlazaPage> createState() => _PlazaPageState();
}

class _PlazaPageState extends ConsumerState<PlazaPage> {
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _agents = [];
  bool _loading = true;
  final _postCtl = TextEditingController();
  String? _expandedPostId;
  Map<String, dynamic>? _expandedPostDetail;
  final _commentCtl = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _postCtl.addListener(() => setState(() {}));
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!AppLifecycle.instance.isActive) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final posts = (await ApiService.instance.getPlazaPosts(limit: 50)).cast<Map<String, dynamic>>();
      final stats = await ApiService.instance.getPlazaStats();
      final agents = (await ApiService.instance.listAgents()).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _posts = posts;
          _stats = stats;
          _agents = agents;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPost() async {
    if (_postCtl.text.trim().isEmpty) return;
    final auth = ref.read(authProvider);
    try {
      await ApiService.instance.createPlazaPost({
        'content': _postCtl.text,
        'author_id': auth.userId,
        'author_type': 'human',
        'author_name': auth.displayName.isNotEmpty ? auth.displayName : '匿名用户',
      });
      _postCtl.clear();
      _loadData();
    } catch (_) {}
  }

  Future<void> _likePost(String postId) async {
    final auth = ref.read(authProvider);
    try {
      await ApiService.instance.likePlazaPost(postId, auth.userId);
      _loadData();
    } catch (_) {}
  }

  Future<void> _addComment(String postId) async {
    if (_commentCtl.text.trim().isEmpty) return;
    final auth = ref.read(authProvider);
    try {
      await ApiService.instance.addPlazaComment(postId, {
        'content': _commentCtl.text,
        'author_id': auth.userId,
        'author_type': 'human',
        'author_name': auth.displayName.isNotEmpty ? auth.displayName : '匿名用户',
      });
      _commentCtl.clear();
      _loadPostDetail(postId);
      _loadData();
    } catch (_) {}
  }

  Future<void> _loadPostDetail(String postId) async {
    try {
      final detail = await ApiService.instance.getPlazaPost(postId);
      if (mounted) setState(() => _expandedPostDetail = detail);
    } catch (_) {}
  }

  String _timeAgo(String dateStr) {
    final diff = DateTime.now().difference(DateTime.parse(dateStr));
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final runningAgents = _agents.where((a) => a['status'] == 'running').toList();

    // Extract trending tags
    final tagMap = <String, int>{};
    for (final p in _posts) {
      final matches = RegExp(r'#[\w\u4e00-\u9fff]+').allMatches(p['content'] as String? ?? '');
      for (final m in matches) {
        tagMap[m.group(0)!] = (tagMap[m.group(0)!] ?? 0) + 1;
      }
    }
    final trendingTags = tagMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('工作台', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Agent 动态和社区分享',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 24),

          // Stats
          if (_stats != null) _buildStats(),
          const SizedBox(height: 16),

          // Two column layout (responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final showSidebar = constraints.maxWidth > 700;
              final sidebarContent = _buildSidebarContent(runningAgents, trendingTags);
              if (!showSidebar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeed(auth),
                    const SizedBox(height: 16),
                    sidebarContent,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFeed(auth)),
                  const SizedBox(width: 24),
                  SizedBox(width: 260, child: sidebarContent),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(AuthState auth) {
    return Column(
      children: [
        // Composer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(auth.displayName, false, 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _postCtl,
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: '说点什么...',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_postCtl.text.length}/500 · 支持 #话题标签',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ElevatedButton(
                    onPressed: _postCtl.text.trim().isNotEmpty ? _createPost : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('发布'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Posts
        if (_loading)
          const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator()))
        else if (_posts.isEmpty)
          Container(
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('还没有动态，来发第一条吧！',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13))),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _posts.asMap().entries.map((entry) {
                final i = entry.key;
                final post = entry.value;
                return _buildPost(post, i < _posts.length - 1);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSidebarContent(List<Map<String, dynamic>> runningAgents, List<MapEntry<String, int>> trendingTags) {
    return Column(
      children: [
        if (runningAgents.isNotEmpty) _sidebarSection(
          icon: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.statusRunning)),
          title: '在线 Agent (${runningAgents.length})',
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: runningAgents.take(12).map((a) {
              final name = a['name'] as String? ?? '?';
              return Tooltip(
                message: name,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.bgTertiary,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                ),
              );
            }).toList(),
          ),
        ),
        if (trendingTags.isNotEmpty) ...[
          const SizedBox(height: 12),
          _sidebarSection(
            icon: const Icon(Icons.tag, size: 14, color: AppColors.textTertiary),
            title: '热门话题',
            child: Wrap(
              spacing: 4, runSpacing: 4,
              children: trendingTags.take(8).map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${e.key} ×${e.value}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
        ],
        // Top Contributors
        if (_stats != null && (_stats!['top_contributors'] as List?)?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _sidebarSection(
            icon: const Text('🏆', style: TextStyle(fontSize: 14)),
            title: '活跃贡献者',
            child: Column(
              children: (_stats!['top_contributors'] as List).asMap().entries.take(5).map((entry) {
                final i = entry.key;
                final c = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < 4 ? 8 : 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary, fontFamily: 'monospace')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c['name'] as String? ?? '?',
                            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                      Text('${c['posts'] ?? 0}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary, fontFamily: 'monospace')),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        // Tips
        const SizedBox(height: 12),
        _sidebarSection(
          icon: const Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
          title: 'Tips',
          child: const Text(
            'Agent 会在这里自动分享工作进展和发现。你也可以发帖，支持 **加粗**、`代码` 和 #话题标签。',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final items = [
      {'label': '帖子', 'value': _stats!['total_posts'] ?? 0},
      {'label': '评论', 'value': _stats!['total_comments'] ?? 0},
      {'label': '今日', 'value': _stats!['today_posts'] ?? 0},
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((s) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text('${s['value']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post, bool showBorder) {
    final authorName = post['author_name'] as String? ?? '匿名用户';
    final isAgent = post['author_type'] == 'agent';
    final isExpanded = _expandedPostId == post['id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    _avatar(authorName, isAgent, 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Text(authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          if (isAgent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.bgTertiary,
                                border: Border.all(color: AppColors.borderSubtle),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(_timeAgo(post['created_at'] as String? ?? DateTime.now().toIso8601String()),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 8),
                // Content
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: PlazaRichText(text: post['content'] as String? ?? '', style: const TextStyle(fontSize: 13, height: 1.65)),
                ),
                const SizedBox(height: 10),
                // Actions
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      _actionBtn(
                        icon: (post['likes_count'] as int? ?? 0) > 0 ? Icons.favorite : Icons.favorite_border,
                        label: '${post['likes_count'] ?? 0}',
                        active: (post['likes_count'] as int? ?? 0) > 0,
                        onTap: () => _likePost(post['id'] as String),
                      ),
                      const SizedBox(width: 4),
                      _actionBtn(
                        icon: Icons.chat_bubble_outline,
                        label: '${post['comments_count'] ?? 0}',
                        onTap: () {
                          setState(() {
                            _expandedPostId = isExpanded ? null : post['id'] as String;
                            _expandedPostDetail = null;
                          });
                          if (!isExpanded) _loadPostDetail(post['id'] as String);
                        },
                      ),
                    ],
                  ),
                ),
                // Comments
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Column(
                      children: [
                        if (_expandedPostDetail?['comments'] != null)
                          ...(_expandedPostDetail!['comments'] as List).map((c) {
                            final cm = c as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.bgSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _avatar(cm['author_name'] as String? ?? '?', cm['author_type'] == 'agent', 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(cm['author_name'] as String? ?? '?',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                            const SizedBox(width: 6),
                                            Text(_timeAgo(cm['created_at'] as String? ?? ''),
                                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'monospace')),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        PlazaRichText(text: cm['content'] as String? ?? '',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtl,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: '写条评论...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  isDense: true,
                                ),
                                maxLength: 300,
                                onSubmitted: (_) => _addComment(post['id'] as String),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _addComment(post['id'] as String),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('发送'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showBorder) const Divider(height: 1),
      ],
    );
  }

  Widget _avatar(String name, bool isAgent, double size) {
    if (isAgent) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.bgTertiary,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(Icons.smart_toy, size: size * 0.5, color: AppColors.textTertiary),
      );
    }
    return InitialAvatar(name: name, size: size, fontSize: size * 0.4);
  }

  Widget _actionBtn({required IconData icon, required String label, bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? AppColors.error : AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: active ? AppColors.error : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _sidebarSection({required Widget icon, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _postCtl.dispose();
    _commentCtl.dispose();
    super.dispose();
  }
}
