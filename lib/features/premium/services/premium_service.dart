import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

/// 🌟 Dan Abramov 結構化不可變會員狀態實體 (Immutable State Machine)
/// 具備嚴密值等價性 (Value Equality)，完全消滅同一狀態再派發造成的無效全域 Rebuild
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
/// 徹底封死任何「非 StoreKit 偽造與代幣白嫖 PRO 通道」，誓死捍衛真金白銀 VVIP 價值防線
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

      // 1. 創始會員祖父條款直升防線 (不可侵犯的承諾)
      final bool isCurrentYearly = isPro && (typeIndex == SubscriptionType.yearly.index);
      final bool isOldProUnmigrated = !alreadyMigrated && isPro;

      if (isCurrentYearly || isOldProUnmigrated) {
        isFounder = true;
        isPro = true;
        typeIndex = SubscriptionType.lifetime.index;
        final founderExpiry = DateTime(2099, 12, 31);
        
        await prefs.setBool('is_founder', true);
        await prefs.setBool('is_pro', true);
        await prefs.setInt('sub_type', typeIndex);
        await prefs.setString('expiry_date', founderExpiry.toIso8601String());
        await prefs.setBool('has_migrated_founder', true);
      }

      // 2. 時光機作弊防線 (系統時間惡意回撥強制自衛)
      final now = DateTime.now();
      String? installStr = prefs.getString('app_install_epoch');
      if (installStr == null) {
        installStr = now.toIso8601String();
        await prefs.setString('app_install_epoch', installStr);
      } else {
        final installTime = DateTime.parse(installStr);
        if (now.isBefore(installTime)) {
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

      // 3. 離線過期白嫖防禦 (非創始會員嚴格校驗有效期限)
      if (isPro && !isFounder && expiryDate != null) {
        if (now.isAfter(expiryDate)) {
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
      state = const PremiumState(isPremium: false);
    }
  }

  Future<void> setPremiumStatus(bool isPro, SubscriptionType type) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? expiry;
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
          break;
        default:
          expiry = null;
      }
    }

    await prefs.setBool('is_pro', isPro);
    await prefs.setInt('sub_type', type.index);
    if (expiry != null) {
      await prefs.setString('expiry_date', expiry.toIso8601String());
    } else {
      await prefs.remove('expiry_date');
    }

    state = state.copyWith(
      isPremium: isPro,
      type: type,
      expiryDate: expiry,
    );
  }

  Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final newBalance = state.coinBalance + amount;
    await prefs.setInt('captain_coins', newBalance);
    state = state.copyWith(coinBalance: newBalance);
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

  /// 🌟 商業防禦重塑：全面廢除「代幣白嫖 PRO 通道」
  /// 捍衛付費會員純度，代幣不再具備解鎖 85 站光纖專線之特權，回歸單純社群榮譽標章
  Future<bool> redeemCoinsForProPass(int coins, int passDays) async {
    // 嚴格阻斷代幣兌換 PRO，保障高客單價付費用戶權益
    debugPrint("🛡️ [商業防線生效] 拒絕代幣兌換 PRO 請求，PRO 特權僅能由 Apple StoreKit 官方購買解鎖。");
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