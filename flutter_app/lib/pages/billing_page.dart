import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../services/purchase_service.dart';
import '../core/theme/app_theme.dart';
import 'enterprise/section_card.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});
  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Map<String, dynamic>? _balance;
  Map<String, dynamic>? _plans;
  bool _loading = true;
  bool _acting = false;
  StreamSubscription<IAPEvent>? _purchaseSub;

  final _purchaseService = PurchaseService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _purchaseSub = _purchaseService.stateStream.listen(_onPurchaseState);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPurchaseState(IAPEvent state) {
    if (!mounted) return;
    switch (state.type) {
      case IAPEventType.purchasing:
        setState(() => _acting = true);
        break;

      case IAPEventType.success:
        setState(() => _acting = false);
        _load(); // refresh balance
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('购买成功！已添加 ${_formatCents(state.addedCents ?? 0)} 额度')),
        );
        break;

      case IAPEventType.error:
        setState(() => _acting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage ?? '购买出错')),
        );
        break;

      case IAPEventType.cancelled:
        setState(() => _acting = false);
        break;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.getBillingBalance(),
        ApiService.instance.getBillingPlans(),
      ]);
      if (mounted) setState(() {
        _balance = results[0];
        _plans = results[1];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manageSubscription() async {
    // Opens Apple's subscription management page
    final url = Uri.parse('https://apps.apple.com/account/subscriptions');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _confirmPurchase(String title, String price, String description) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(price, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accentPrimary)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认购买'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _subscribe() async {
    if (_purchaseService.available && _purchaseService.products.containsKey(PurchaseService.proMonthlyId)) {
      await _purchaseService.buySubscription();
    } else {
      final price = _subscriptionPrice();
      if (!await _confirmPurchase('Pro 月度订阅', '$price/月', '每月获得等额 Token 额度，余额可累积')) return;
      setState(() => _acting = true);
      try {
        final result = await ApiService.instance.subscribe();
        await _load();
        if (mounted) {
          final added = result['added_credit_cents'] as int? ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('订阅成功！已添加 ${_formatCents(added)} 额度')),
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
  }

  Future<void> _buyCredits() async {
    if (_purchaseService.available && _purchaseService.products.containsKey(PurchaseService.creditPackId)) {
      await _purchaseService.buyCreditPack();
    } else {
      final price = _creditPackPrice();
      if (!await _confirmPurchase('额度充值包', price, '即买即用，永不过期')) return;
      setState(() => _acting = true);
      try {
        final result = await ApiService.instance.buyCredits();
        await _load();
        if (mounted) {
          final added = result['added_credit_cents'] as int? ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('充值成功！已添加 ${_formatCents(added)} 额度')),
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
  }

  String _formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  /// Get price: StoreKit > backend plans > hardcoded fallback
  String _subscriptionPrice() {
    final product = _purchaseService.products[PurchaseService.proMonthlyId];
    if (product != null) return product.price;
    final plans = (_plans?['subscription_plans'] as List?)?.cast<Map<String, dynamic>>();
    if (plans != null && plans.isNotEmpty) {
      return _formatCents(plans.first['price_cents'] as int? ?? 2999);
    }
    return '\$29.99';
  }

  String _creditPackPrice() {
    final product = _purchaseService.products[PurchaseService.creditPackId];
    if (product != null) return product.price;
    final packs = (_plans?['credit_packs'] as List?)?.cast<Map<String, dynamic>>();
    if (packs != null && packs.isNotEmpty) {
      return _formatCents(packs.first['price_cents'] as int? ?? 1999);
    }
    return '\$19.99';
  }

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
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('订阅方案'),
                  const SizedBox(height: 8),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('额外充值'),
                  const SizedBox(height: 8),
                  _buildCreditPackCard(),
                  const SizedBox(height: 24),
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
    final price = _subscriptionPrice();

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
                    Text('$price/月 · 含等额 Token 额度',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '· 每月获得等额 Token 使用额度\n· 未用完的额度自动累积到下月\n· 可随时购买额外额度包',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isSubscribed
                ? OutlinedButton.icon(
                    onPressed: _manageSubscription,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPrimary,
                      side: const BorderSide(color: AppColors.accentPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('管理订阅', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton(
                    onPressed: _acting ? null : _subscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _acting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('订阅 · $price/月',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackCard() {
    final price = _creditPackPrice();
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
                Text('$price/包 · 即买即用，永不过期',
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
                : Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
