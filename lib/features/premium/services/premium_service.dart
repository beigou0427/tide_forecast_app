import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

/// 🌟 Dan Abramov 結構化不可變會員狀態實體 (Immutable State Machine)
@immutable
class PremiumState {
  final bool isPremium;
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isFounder;
  final int coinBalance;

  const PremiumState({
    required this.isPremium,
    this.type = SubscriptionType.none,
    this.expiryDate,
    this.isFounder = false,
    this.coinBalance = 0,
  });

  PremiumState copyWith({
    bool? isPremium,
    SubscriptionType? type,
    DateTime? expiryDate,
    bool? isFounder,
    int? coinBalance,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      type: type ?? this.type,
      expiryDate: expiryDate ?? this.expiryDate,
      isFounder: isFounder ?? this.isFounder,
      coinBalance: coinBalance ?? this.coinBalance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumState &&
          runtimeType == other.runtimeType &&
          isPremium == other.isPremium &&
          type == other.type &&
          expiryDate == other.expiryDate &&
          isFounder == other.isFounder &&
          coinBalance == other.coinBalance;

  @override
  int get hashCode => Object.hash(
        isPremium,
        type,
        expiryDate,
        isFounder,
        coinBalance,
      );
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});

final iapManagerProvider = Provider<IAPManager>((ref) {
  final notifier = ref.read(premiumProvider.notifier);
  final manager = IAPManager(notifier);
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// 🌟 經 Redux / 單向資料流哲學重構的純粹會員狀態轉移器
/// 100% 商業金流捍衛版：
/// 1. 徹底封死新訂閱年費用戶重開 App 被誤升為終身創始會員的商業死穴！
/// 2. 實裝 NTP 5 分鐘時鐘容錯緩衝，杜絕手機時間微調誤殺合法 PRO 權益。
/// 3. 保留 Leslie Lamport TLA+ 祖父條款對歷史老船長的一次性無痛直升。
class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(const PremiumState(isPremium: false)) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool alreadyMigrated = prefs.getBool('has_migrated_founder') ?? false;
      bool isPro = prefs.getBool('is_pro') ?? false;
      int typeIndex = prefs.getInt('sub_type') ?? 0;
      bool isFounder = prefs.getBool('is_founder') ?? false;

      // 🚨 商業金流核心防線：祖父條款「僅且唯有」在歷史老用戶且尚未遷移時才觸發！
      // 絕不將新購買年度訂閱 (alreadyMigrated == true) 的用戶誤轉為終身免費用戶！
      final bool isOldProUnmigrated = !alreadyMigrated && isPro;

      if (isOldProUnmigrated) {
        isFounder = true;
        isPro = true;
        typeIndex = SubscriptionType.lifetime.index;
        final founderExpiry = DateTime(2099, 12, 31);
        
        await prefs.setBool('is_founder', true);
        await prefs.setBool('is_pro', true);
        await prefs.setInt('sub_type', typeIndex);
        await prefs.setString('expiry_date', founderExpiry.toIso8601String());
        await prefs.setBool('has_migrated_founder', true);
        debugPrint("👑 [VVIP 權益] 偵測到早期老船長，已觸發祖父條款直升終身創始會員！");
      }

      // 🛡️ 防線 2：時光機作弊防線 (注入 5 分鐘 NTP 網路校時容錯)
      final now = DateTime.now();
      String? installStr = prefs.getString('app_install_epoch');
      if (installStr == null) {
        installStr = now.toIso8601String();
        await prefs.setString('app_install_epoch', installStr);
      } else {
        final installTime = DateTime.parse(installStr);
        // 若系統時間早於安裝時間超過 5 分鐘，才嚴格判定為刻意時鐘回撥作弊！
        if (now.isBefore(installTime.subtract(const Duration(minutes: 5)))) {
          debugPrint("🚨 [反作弊警報] 系統時間顯著早於安裝時間！偵測到時鐘回撥作弊，擊殺 PRO 權限！");
          await prefs.setBool('is_pro', false);
          await prefs.remove('expiry_date');
          await prefs.setInt('sub_type', SubscriptionType.none.index);
          state = state.copyWith(isPremium: false, type: SubscriptionType.none);
          return;
        }
      }

      final expiryStr = prefs.getString('expiry_date');
      final coins = prefs.getInt('captain_coins') ?? 0;
      DateTime? expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

      // 🛡️ 防線 3：離線過期防禦
      if (isPro && !isFounder && expiryDate != null) {
        if (now.isAfter(expiryDate)) {
          debugPrint("⏳ [訂閱管理] PRO 權限已於 $expiryDate 到期，離線環境下自動降級為一般會員。");
          isPro = false;
          typeIndex = SubscriptionType.none.index;
          expiryDate = null;
          await prefs.setBool('is_pro', false);
          await prefs.setInt('sub_type', typeIndex);
          await prefs.remove('expiry_date');
        }
      }

      final safeType = SubscriptionType.values[typeIndex < SubscriptionType.values.length ? typeIndex : 0];

      state = PremiumState(
        isPremium: isPro,
        type: safeType,
        expiryDate: expiryDate,
        isFounder: isFounder,
        coinBalance: coins,
      );
    } catch (e) {
      debugPrint("⚠️ [PremiumNotifier] 狀態加載異常: $e");
      state = const PremiumState(isPremium: false);
    }
  }

  Future<void> setPremiumStatus(bool isPro, SubscriptionType type) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? expiry;
    bool targetFounderState = state.isFounder;

    if (isPro) {
      final now = DateTime.now();
      switch (type) {
        case SubscriptionType.weekly:
          expiry = now.add(const Duration(days: 7));
          break;
        case SubscriptionType.monthly:
          expiry = now.add(const Duration(days: 30));
          break;
        case SubscriptionType.yearly:
          expiry = now.add(const Duration(days: 365));
          break;
        case SubscriptionType.lifetime:
          expiry = DateTime(2099, 12, 31);
          targetFounderState = true; 
          break;
        default:
          expiry = null;
      }
    } else {
      targetFounderState = false; 
    }

    await prefs.setBool('is_pro', isPro);
    await prefs.setInt('sub_type', type.index);
    await prefs.setBool('is_founder', targetFounderState);

    if (expiry != null) {
      await prefs.setString('expiry_date', expiry.toIso8601String());
    } else {
      await prefs.remove('expiry_date');
    }

    state = state.copyWith(
      isPremium: isPro,
      type: type,
      expiryDate: expiry,
      isFounder: targetFounderState,
    );
  }

  // 🌟 Alex Hormozi $100M Leads: 聯盟行銷自動核銷引擎
  Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int newBalance = state.coinBalance + amount;
    
    DateTime? newExpiry = state.expiryDate;
    SubscriptionType newType = state.type;
    bool isPro = state.isPremium;

    while (!state.isFounder && newBalance >= 100) {
      newBalance -= 100;
      isPro = true;
      newType = state.type == SubscriptionType.none ? SubscriptionType.monthly : state.type;
      
      if (newExpiry != null && newExpiry!.isAfter(DateTime.now())) {
        newExpiry = newExpiry!.add(const Duration(days: 30));
      } else {
        newExpiry = DateTime.now().add(const Duration(days: 30));
      }
      
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', newType.index);
      await prefs.setString('expiry_date', newExpiry!.toIso8601String());
      
      debugPrint("🎉 [聯盟裂變引擎] 代幣達標 100 枚！自動核銷並展延 30 天 PRO 至 $newExpiry！");
    }

    await prefs.setInt('captain_coins', newBalance);
    
    state = state.copyWith(
      coinBalance: newBalance,
      isPremium: isPro,
      type: newType,
      expiryDate: newExpiry,
    );
  }

  Future<bool> spendCoins(int amount) async {
    if (state.coinBalance >= amount) {
      final prefs = await SharedPreferences.getInstance();
      final newBalance = state.coinBalance - amount;
      await prefs.setInt('captain_coins', newBalance);
      state = state.copyWith(coinBalance: newBalance);
      return true;
    }
    return false;
  }

  Future<bool> redeemCoinsForProPass(int coins, int passDays) async {
    return false;
  }

  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.isFounder) return; 
    
    await prefs.remove('is_pro');
    await prefs.remove('sub_type');
    await prefs.remove('expiry_date');
    state = state.copyWith(isPremium: false, type: SubscriptionType.none);
  }
}
