import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// 🌟 核心修正：直接引入 StoreKit 底層 Wrapper 檔案以消除紅字
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../../core/utils/constants.dart';
import 'premium_service.dart';

class IAPManager {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final PremiumNotifier premiumNotifier;

  IAPManager(this.premiumNotifier) {
    // 1. 初始化交易監聽流
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) => _listenToPurchaseUpdated(purchaseDetailsList),
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("🚨 IAP 串流錯誤: $error"),
    );
  }

  /// 2. 核心邏輯：處理所有交易狀態更新
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("⏳ 交易處理中...");
      } 
      else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("❌ 購買出錯: ${purchaseDetails.error}");
        _finishTransaction(purchaseDetails);
      } 
      else if (purchaseDetails.status == PurchaseStatus.purchased ||
               purchaseDetails.status == PurchaseStatus.restored) {
        
        // 🌟 成功購買或恢復，執行收據驗證
        bool valid = await _verifyPurchase(purchaseDetails);
        
        if (valid) {
          // 判定是月費還是年費 (對應 Constants 裡的 ID)
          final type = (purchaseDetails.productID == AppConstants.iapProYearly)
              ? SubscriptionType.yearly
              : SubscriptionType.monthly;

          // 通知 PremiumService 更新本地狀態與 UI
          await premiumNotifier.setPremiumStatus(true, type);
          debugPrint("✅ Pro 權限已解鎖: $type");
        }

        _finishTransaction(purchaseDetails);
      } 
      else if (purchaseDetails.status == PurchaseStatus.canceled) {
        debugPrint("🚫 使用者取消了交易");
        _finishTransaction(purchaseDetails);
      }
    }
  }

  /// 3. 獲取商店產品 (月費/年費) 真實資訊與價格
  Future<List<ProductDetails>> fetchProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("❌ 商店目前無法連線");
      return [];
    }

    final ProductDetailsResponse response = 
        await _iap.queryProductDetails(AppConstants.iapProductIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("⚠️ 找不到產品 ID: ${response.notFoundIDs}");
    }

    return response.productDetails;
  }

  /// 4. 執行購買
  Future<void> buySubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      if (Platform.isIOS) {
        // 🌟 針對 iOS 的特殊處理：清理舊的交易隊列
        // 這裡使用的是 store_kit_wrappers.dart 提供的類別
        final SKPaymentQueueWrapper queueWrapper = SKPaymentQueueWrapper();
        final List<SKPaymentTransactionWrapper> transactions = await queueWrapper.transactions();
        
        for (final SKPaymentTransactionWrapper transaction in transactions) {
          // 只有非進行中的交易才手動結束，避免卡住
          if (transaction.transactionState != SKPaymentTransactionStateWrapper.purchasing) {
            await queueWrapper.finishTransaction(transaction);
          }
        }
      }
      
      // 自動續期訂閱使用 buyNonConsumable
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("🚨 發起購買失敗: $e");
    }
  }

  /// 5. 恢復購買 (Apple 審核必備功能)
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint("🚨 恢復購買失敗: $e");
    }
  }

  /// 輔助方法：標記交易完成
  Future<void> _finishTransaction(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  /// 驗證邏輯 (本地端簡單模擬)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // 正式環境應將 purchaseDetails.verificationData 送至後端驗證
    return true; 
  }

  void dispose() {
    _subscription.cancel();
  }
}