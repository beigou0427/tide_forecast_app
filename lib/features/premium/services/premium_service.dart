import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

/// 1. 定義訂閱類型 (月費、年費、無)
enum SubscriptionType { none, monthly, yearly }

/// 2. 定義 Premium 狀態模型
class PremiumState {
  final bool isPremium;
  final SubscriptionType type;
  final DateTime? expiryDate;

  PremiumState({
    required this.isPremium,
    this.type = SubscriptionType.none,
    this.expiryDate,
  });

  /// 輔助方法：將狀態轉為 Map 以便觀察
  Map<String, dynamic> toJson() => {
    'isPremium': isPremium,
    'type': type.index,
    'expiryDate': expiryDate?.toIso8601String(),
  };
}

/// 3. 提供訂閱狀態的 Provider (UI 監聽此項)
final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});

/// 4. 提供 IAP 管理員的 Provider
/// 將 PremiumNotifier 注入其中，讓交易成功時能自動更新狀態
final iapManagerProvider = Provider<IAPManager>((ref) {
  final notifier = ref.read(premiumProvider.notifier);
  final manager = IAPManager(notifier);
  
  // 當 Provider 銷毀時（例如使用者登出），自動關閉 IAP 監聽流
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// 5. 訂閱狀態管理邏輯中心
class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(PremiumState(isPremium: false)) {
    _loadStatus();
  }

  /// 從手機本地儲存載入訂閱狀態
  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPro = prefs.getBool('is_pro') ?? false;
      final typeIndex = prefs.getInt('sub_type') ?? 0;
      final expiryStr = prefs.getString('expiry_date');

      state = PremiumState(
        isPremium: isPro,
        type: SubscriptionType.values[typeIndex],
        expiryDate: expiryStr != null ? DateTime.parse(expiryStr) : null,
      );
    } catch (e) {
      // 若載入失敗則預設為非付費會員
      state = PremiumState(isPremium: false);
    }
  }

  /// 🌟 核心方法：由 IAPManager 成功驗證收據後呼叫
  /// 負責更新狀態並存入本地儲存
  Future<void> setPremiumStatus(bool isPro, SubscriptionType type) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 計算模擬到期日 (正式環境建議由伺服器端判斷)
    DateTime? expiry;
    if (isPro) {
      final now = DateTime.now();
      expiry = (type == SubscriptionType.yearly) 
          ? now.add(const Duration(days: 365)) 
          : now.add(const Duration(days: 30));
    }

    // 持久化儲存數據
    await prefs.setBool('is_pro', isPro);
    await prefs.setInt('sub_type', type.index);
    if (expiry != null) {
      await prefs.setString('expiry_date', expiry.toIso8601String());
    } else {
      await prefs.remove('expiry_date');
    }

    // 發送通知給所有監聽者 (UI 會立即刷新)
    state = PremiumState(
      isPremium: isPro,
      type: type,
      expiryDate: expiry,
    );
  }

  /// 測試用：手動購買 (模擬購買流程)
  Future<void> purchase(SubscriptionType type) async {
    // 這裡直接執行狀態變更，讓開發期間不用連商店也能測試 UI
    await setPremiumStatus(true, type);
  }

  /// 測試用：還原/重置狀態
  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 清除本地紀錄
    state = PremiumState(isPremium: false, type: SubscriptionType.none);
  }
}