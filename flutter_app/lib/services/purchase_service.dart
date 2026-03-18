import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api.dart';

/// Singleton service for Apple/Google In-App Purchase.
///
/// Call [init] once at app startup. Use [buySubscription] / [buyCreditPack]
/// to trigger purchases. The service automatically verifies receipts with
/// the backend and completes transactions with StoreKit.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  // Product IDs — must match App Store Connect configuration
  static const proMonthlyId = 'pro_monthly';
  static const creditPackId = 'credit_pack_20';
  static const _productIds = {proMonthlyId, creditPackId};

  // Loaded product details from StoreKit
  final Map<String, ProductDetails> _products = {};

  /// Whether IAP is available on this device.
  bool _available = false;
  bool get available => _available;

  /// Products loaded from StoreKit, keyed by product ID.
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  /// Stream controller for purchase state changes (UI can listen).
  final _stateController = StreamController<IAPEvent>.broadcast();
  Stream<IAPEvent> get stateStream => _stateController.stream;

  /// Initialize IAP — call once from main.dart.
  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('[PurchaseService] IAP not available on this device');
      return;
    }

    // Listen to purchase updates
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('[PurchaseService] purchaseStream error: $error');
        _stateController.add(IAPEvent.error('购买流程出错: $error'));
      },
    );

    // Load product details from StoreKit
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('[PurchaseService] queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[PurchaseService] Products not found: ${response.notFoundIDs}');
    }
    for (final p in response.productDetails) {
      _products[p.id] = p;
    }
    debugPrint('[PurchaseService] Loaded ${_products.length} products: ${_products.keys}');
  }

  /// Buy Pro monthly subscription.
  Future<void> buySubscription() async {
    final product = _products[proMonthlyId];
    if (product == null) {
      _stateController.add(IAPEvent.error('订阅产品未加载，请稍后再试'));
      return;
    }
    _stateController.add(IAPEvent.purchasing());
    // Auto-renewing subscriptions use buyNonConsumable
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Buy $20 credit pack (consumable).
  Future<void> buyCreditPack() async {
    final product = _products[creditPackId];
    if (product == null) {
      _stateController.add(IAPEvent.error('充值产品未加载，请稍后再试'));
      return;
    }
    _stateController.add(IAPEvent.purchasing());
    final param = PurchaseParam(productDetails: product);
    // autoConsume: false — we verify with backend first, then completePurchase
    await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
  }

  /// Handle purchase stream updates from StoreKit.
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      debugPrint('[PurchaseService] Purchase update: ${p.productID} status=${p.status}');

      switch (p.status) {
        case PurchaseStatus.purchased:
          await _verifyAndComplete(p);
          break;

        case PurchaseStatus.error:
          final errorMsg = p.error?.message ?? '未知错误';
          debugPrint('[PurchaseService] Purchase error: $errorMsg');
          _stateController.add(IAPEvent.error('购买失败: $errorMsg'));
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('[PurchaseService] Purchase cancelled');
          _stateController.add(IAPEvent.cancelled());
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;

        case PurchaseStatus.pending:
          debugPrint('[PurchaseService] Purchase pending');
          _stateController.add(IAPEvent.purchasing());
          break;

        default:
          // Handle restored or future status values
          debugPrint('[PurchaseService] Unhandled status: ${p.status}');
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  /// Send receipt to backend for verification, then complete the transaction.
  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    try {
      // Get the receipt data (iOS only; on Android this would be different)
      String receiptData = '';
      if (Platform.isIOS) {
        receiptData = purchase.verificationData.localVerificationData;
      } else {
        // Android: use serverVerificationData
        receiptData = purchase.verificationData.serverVerificationData;
      }

      final transactionId = purchase.purchaseID ?? '';
      if (transactionId.isEmpty) {
        debugPrint('[PurchaseService] No transaction ID, cannot verify');
        _stateController.add(IAPEvent.error('无法获取交易ID'));
        return;
      }

      // Send to backend for verification
      final result = await ApiService.instance.verifyAppleReceipt(
        receiptData: receiptData,
        productId: purchase.productID,
        transactionId: transactionId,
      );

      debugPrint('[PurchaseService] Backend verification result: $result');

      // CRITICAL: Must call completePurchase to finalize with Apple.
      // Without this, Apple will auto-refund after 3 days.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      final addedCents = result['added_credit_cents'] as int? ?? 0;
      final balanceCents = result['credit_balance_cents'] as int? ?? 0;
      _stateController.add(IAPEvent.success(
        addedCents: addedCents,
        balanceCents: balanceCents,
      ));
    } catch (e) {
      debugPrint('[PurchaseService] Verification failed: $e');
      _stateController.add(IAPEvent.error('验证购买失败: $e'));

      // Still complete the purchase to avoid stuck transactions.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    _stateController.close();
  }
}

/// IAP event types for UI updates.
enum IAPEventType { purchasing, success, error, cancelled }

/// Purchase state event for UI updates.
class IAPEvent {
  final IAPEventType type;
  final String? errorMessage;
  final int? addedCents;
  final int? balanceCents;

  IAPEvent._({
    required this.type,
    this.errorMessage,
    this.addedCents,
    this.balanceCents,
  });

  factory IAPEvent.purchasing() => IAPEvent._(type: IAPEventType.purchasing);

  factory IAPEvent.success({required int addedCents, required int balanceCents}) =>
      IAPEvent._(type: IAPEventType.success, addedCents: addedCents, balanceCents: balanceCents);

  factory IAPEvent.error(String message) =>
      IAPEvent._(type: IAPEventType.error, errorMessage: message);

  factory IAPEvent.cancelled() => IAPEvent._(type: IAPEventType.cancelled);
}
