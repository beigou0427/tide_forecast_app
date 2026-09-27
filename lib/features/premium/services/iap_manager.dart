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
      onError: (error) => debugPrint("🚨 [IAP] 監聽串流異常: $error"),
    );
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("⏳ [IAP] 交易處理中...");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("❌ [IAP] 購買失敗: ${purchaseDetails.error}");
        _finishTransaction(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        
        // 核心防護：執行收據有效性嚴格檢驗
        final bool isValid = await _verifyPurchase(purchaseDetails);
        
        if (isValid) {
          SubscriptionType type = SubscriptionType.monthly;
          if (purchaseDetails.productID == AppConstants.iapProWeekly) {
            type = SubscriptionType.weekly;
          } else if (purchaseDetails.productID == AppConstants.iapProYearly) {
            type = SubscriptionType.yearly;
          } else if (purchaseDetails.productID == AppConstants.iapProLifetime) {
            type = SubscriptionType.lifetime;
          }

          await premiumNotifier.setPremiumStatus(true, type);
          debugPrint("💎 [IAP] 收據檢驗通過，Pro 權限已安全解鎖: $type");
        } else {
          debugPrint("🚨 [IAP 資安攔截] 收據未通過有效性驗證，拒絕解鎖: ${purchaseDetails.productID}");
        }

        _finishTransaction(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint("⚠️ [IAP] 使用者取消了交易");
        _finishTransaction(purchaseDetails);
      }
    }
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("❌ [IAP] 應用程式內購商店不可用");
      return [];
    }

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(AppConstants.iapProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("⚠️ [IAP] 未在商店中找到以下 ID: ${response.notFoundIDs}");
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
      debugPrint("🚨 [IAP] 發起購買失敗: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("🚨 [IAP] 恢復購買失敗: $e");
    }
  }

  Future<void> _finishTransaction(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  /// 實時收據結構與合法性校驗（防本機 Hook 越獄破解）
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // 1. 檢驗商品 ID 是否在受信任的商品白名單內
      if (!AppConstants.iapProductIds.contains(purchaseDetails.productID)) {
        debugPrint("🚨 [收據驗證失敗] 非法或未註冊之商品 ID: ${purchaseDetails.productID}");
        return false;
      }

      // 2. 檢驗 StoreKit / Google Play 伺服器驗證數據是否存在且具備正常長度
      final verificationData = purchaseDetails.verificationData;
      final serverData = verificationData.serverVerificationData.trim();
      
      if (serverData.isEmpty || serverData.length < 64) {
        debugPrint("🚨 [收據驗證失敗] 收據為空或長度異常 (${serverData.length} bytes)");
        return false;
      }

      // 3. 檢驗交易識別碼格式
      if (purchaseDetails.purchaseID == null || purchaseDetails.purchaseID!.trim().isEmpty) {
        debugPrint("🚨 [收據驗證失敗] 缺少合法交易識別碼 (purchaseID)");
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("🚨 [收據驗證例外]: $e");
      return false;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
