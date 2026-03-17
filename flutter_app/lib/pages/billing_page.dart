import 'package:flutter/material.dart';
import '../services/api.dart';
import '../core/theme/app_theme.dart';
import 'enterprise/section_card.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Map<String, dynamic>? _balance;
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getBillingBalance();
      if (mounted) setState(() { _balance = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _subscribe() async {
    setState(() => _acting = true);
    try {
      await ApiService.instance.subscribe();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订阅成功！已添加 \$29.9 额度')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('订阅失败: $e')),
        );
      }
    }
    if (mounted) setState(() => _acting = false);
  }

  Future<void> _buyCredits() async {
    setState(() => _acting = true);
    try {
      await ApiService.instance.buyCredits();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('充值成功！已添加 \$20 额度')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('充值失败: $e')),
        );
      }
    }
    if (mounted) setState(() => _acting = false);
  }

  String _formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('额度与订阅'),
        backgroundColor: AppColors.bgSecondary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Balance card
                  _buildBalanceCard(),
                  const SizedBox(height: 24),

                  // Subscription section
                  _sectionTitle('订阅方案'),
                  const SizedBox(height: 8),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),

                  // Credit pack section
                  _sectionTitle('额外充值'),
                  const SizedBox(height: 8),
                  _buildCreditPackCard(),
                  const SizedBox(height: 24),

                  // Info
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _balance?['credit_balance_cents'] as int? ?? 0;
    final used = _balance?['total_used_cents'] as int? ?? 0;
    final purchased = _balance?['total_purchased_cents'] as int? ?? 0;
    final tier = _balance?['subscription_tier'] as String? ?? 'free';
    final expiresAt = _balance?['subscription_expires_at'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentPrimary.withValues(alpha: 0.2), AppColors.bgElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: AppColors.accentPrimary, size: 24),
              const SizedBox(width: 8),
              Text('当前余额', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tier == 'pro'
                      ? AppColors.accentPrimary.withValues(alpha: 0.15)
                      : AppColors.textTertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tier == 'pro' ? 'Pro' : '免费',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tier == 'pro' ? AppColors.accentPrimary : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCents(balance),
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem('累计购买', _formatCents(purchased)),
              const SizedBox(width: 24),
              _statItem('已消费', _formatCents(used)),
            ],
          ),
          if (tier == 'pro' && expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '订阅到期: ${_formatDate(expiresAt)}',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        Text(value, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    final tier = _balance?['subscription_tier'] as String? ?? 'free';
    final isSubscribed = tier == 'pro';

    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, color: AppColors.accentPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pro 月度订阅',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('\$29.9/月 · 含 \$29.9 Token 额度',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '· 每月获得 \$29.9 的 Token 使用额度\n· 未用完的额度自动累积到下月\n· 可随时购买额外额度包',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acting ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _acting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isSubscribed ? '续费 · \$29.9' : '订阅 · \$29.9/月',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackCard() {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('额度充值包',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('\$20/包 · 即买即用，永不过期',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _acting ? null : _buyCredits,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _acting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('\$20', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('说明', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            '· Token 额度按实际使用量扣费，不同模型费率不同\n'
            '· 经济模型（如 GPT-4o Mini）约 \$0.6/百万 Token\n'
            '· 高级模型（如 Claude Sonnet 4）约 \$15/百万 Token\n'
            '· 未用完的额度不会清零，自动累积',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
