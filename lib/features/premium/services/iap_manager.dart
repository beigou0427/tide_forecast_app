import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../core/utils/constants.dart';
import 'premium_service.dart';

class IAPManager {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final PremiumNotifier premiumNotifier;

  IAPManager(this.premiumNotifier) {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) => _listenToPurchaseUpdated(purchaseDetailsList),
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("🚨 IAP 監聽串流異常: $error"),
    );
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("⏳ 交易處理中...");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("❌ 購買失敗: ${purchaseDetails.error}");
        _finishTransaction(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        
        bool valid = await _verifyPurchase(purchaseDetails);
        
        if (valid) {
          SubscriptionType type = SubscriptionType.monthly;
          if (purchaseDetails.productID == AppConstants.iapProWeekly) {
            type = SubscriptionType.weekly;
          } else if (purchaseDetails.productID == AppConstants.iapProYearly) {
            type = SubscriptionType.yearly;
          } else if (purchaseDetails.productID == AppConstants.iapProLifetime) {
            type = SubscriptionType.lifetime;
          }

          await premiumNotifier.setPremiumStatus(true, type);
          debugPrint("💎 Pro 權限已解鎖: $type");
        }

        _finishTransaction(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint("⚠️ 使用者取消了交易");
        _finishTransaction(purchaseDetails);
      }
    }
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("❌ 應用程式內購商店不可用");
      return [];
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(AppConstants.iapProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("⚠️ 未在商店中找到以下 ID: ${response.notFoundIDs}");
    }

    return response.productDetails;
  }

  Future<void> buySubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      if (Platform.isIOS) {
        final SKPaymentQueueWrapper queueWrapper = SKPaymentQueueWrapper();
        final List<SKPaymentTransactionWrapper> transactions = await queueWrapper.transactions();
        
        for (final SKPaymentTransactionWrapper transaction in transactions) {
          if (transaction.transactionState != SKPaymentTransactionStateWrapper.purchasing) {
            await queueWrapper.finishTransaction(transaction);
          }
        }
      }
      
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("🚨 發起購買失敗: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("🚨 恢復購買失敗: $e");
    }
  }

  Future<void> _finishTransaction(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    return true; 
  }

  void dispose() {
    _subscription.cancel();
  }
}
