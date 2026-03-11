import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../services/api.dart';

class InvitationCodesPage extends ConsumerStatefulWidget {
  const InvitationCodesPage({super.key});

  @override
  ConsumerState<InvitationCodesPage> createState() => _InvitationCodesPageState();
}

class _InvitationCodesPageState extends ConsumerState<InvitationCodesPage> {
  bool _enabled = false;
  List<dynamic> _codes = [];
  int _total = 0;
  int _page = 1;
  final int _pageSize = 20;
  String _search = '';
  int _batchCount = 5;
  int _maxUses = 5;
  bool _creating = false;
  bool _loading = true;
  String? _toast;

  final _searchCtrl = TextEditingController();
  final _batchCountCtrl = TextEditingController(text: '5');
  final _maxUsesCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _loadSetting();
    _loadCodes();
  }

  Future<void> _loadSetting() async {
    try {
      final data = await ApiService.instance.getInvitationSetting();
      if (mounted) {
        final val = data['value'];
        setState(() => _enabled = val is Map ? (val['enabled'] == true) : false);
      }
    } catch (_) {}
  }

  Future<void> _loadCodes({int? page, String? search}) async {
    final p = page ?? _page;
    final q = search ?? _search;
    try {
      final data = await ApiService.instance.listInvitationCodes(page: p, pageSize: _pageSize, search: q.isNotEmpty ? q : null);
      if (mounted) {
        setState(() {
          _codes = data['items'] as List<dynamic>? ?? [];
          _total = data['total'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalPages => (_total / _pageSize).ceil().clamp(1, 999);

  Future<void> _toggleEnabled() async {
    final newVal = !_enabled;
    try {
      await ApiService.instance.setInvitationSetting(newVal);
      setState(() => _enabled = newVal);
    } catch (_) {}
  }

  Future<void> _createBatch() async {
    setState(() => _creating = true);
    try {
      await ApiService.instance.createInvitationCodes(_batchCount, _maxUses);
      setState(() { _page = 1; _search = ''; });
      _searchCtrl.clear();
      await _loadCodes(page: 1, search: '');
      _showToast('Codes created!');
    } catch (_) {}
    if (mounted) setState(() => _creating = false);
  }

  Future<void> _deactivate(String id) async {
    try {
      await ApiService.instance.deactivateInvitationCode(id);
      _loadCodes();
    } catch (_) {}
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('邀请码', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Manage invitation codes for platform registration.',
                      style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  const SizedBox(height: 24),

                  // Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _enabled ? AppColors.success : AppColors.borderSubtle, width: _enabled ? 2 : 1),
                      color: _enabled ? AppColors.success.withValues(alpha: 0.06) : AppColors.bgSecondary,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Require Invitation Code for Registration',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              const Text('When enabled, new users must provide a valid invitation code to register.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleEnabled,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _enabled ? AppColors.success : AppColors.bgTertiary,
                              border: Border.all(color: _enabled ? AppColors.success : AppColors.borderSubtle, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _enabled ? Colors.white : AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_enabled ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: _enabled ? Colors.white : AppColors.textTertiary,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Batch create
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                      color: AppColors.bgSecondary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('创建邀请码', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Number of Codes', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _batchCountCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(isDense: true),
                                    onChanged: (v) => _batchCount = int.tryParse(v) ?? 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Max Uses per Code', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _maxUsesCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: const InputDecoration(isDense: true),
                                    onChanged: (v) => _maxUses = int.tryParse(v) ?? 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _creating ? null : _createBatch,
                              child: Text(_creating ? 'Creating...' : 'Generate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Codes table
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                      color: AppColors.bgSecondary,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('All Invitation Codes ($_total)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: const InputDecoration(
                                  hintText: '搜索...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (v) {
                                  setState(() { _search = v; _page = 1; });
                                  _loadCodes(page: 1, search: v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                          ),
                          child: Row(
                            children: const [
                              Expanded(flex: 3, child: Text('CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.05))),
                              Expanded(flex: 1, child: Text('USAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))),
                              Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))),
                              Expanded(flex: 1, child: Text('CREATED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary))),
                              SizedBox(width: 80),
                            ],
                          ),
                        ),
                        if (_loading)
                          const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2))
                        else if (_codes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No data', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          )
                        else
                          ...(_codes.map((c) {
                            final code = c as Map<String, dynamic>;
                            final isActive = code['is_active'] == true;
                            final usedCount = code['used_count'] as int? ?? 0;
                            final maxUses = code['max_uses'] as int? ?? 0;
                            final createdAt = code['created_at'] as String?;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(code['code'] as String? ?? '', style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500, letterSpacing: 1)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(text: '$usedCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                          TextSpan(text: ' / $maxUses', style: const TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: _buildStatusBadge(isActive, usedCount, maxUses),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      createdAt != null ? DateTime.tryParse(createdAt)?.toLocal().toString().split(' ').first ?? '-' : '-',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: isActive && usedCount < maxUses
                                        ? TextButton(
                                            onPressed: () => _deactivate(code['id'] as String),
                                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                            child: const Text('Disable', style: TextStyle(fontSize: 10)),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            );
                          })),

                        // Pagination
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _page > 1 ? () { setState(() => _page--); _loadCodes(); } : null,
                                  icon: const Icon(Icons.chevron_left, size: 18),
                                ),
                                Text('$_page / $_totalPages', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                IconButton(
                                  onPressed: _page < _totalPages ? () { setState(() => _page++); _loadCodes(); } : null,
                                  icon: const Icon(Icons.chevron_right, size: 18),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Toast
        if (_toast != null)
          Positioned(
            top: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_toast!, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive, int usedCount, int maxUses) {
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.textTertiary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Disabled', style: TextStyle(color: Colors.white, fontSize: 10)),
      );
    }
    if (usedCount >= maxUses) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Exhausted', style: TextStyle(color: Colors.white, fontSize: 10)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _batchCountCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }
}
