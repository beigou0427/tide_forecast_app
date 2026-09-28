import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

class PremiumState {
  final bool isPremium;
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isFounder;
  final int coinBalance;

  PremiumState({
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

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(PremiumState(isPremium: false)) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool alreadyMigrated = prefs.getBool('has_migrated_founder') ?? false;
      bool isPro = prefs.getBool('is_pro') ?? false;
      int typeIndex = prefs.getInt('sub_type') ?? 0;
      bool isFounder = prefs.getBool('is_founder') ?? false;

      // 🌟 老闆英明決策：現行年度訂閱 (Yearly) 老客戶無痛直升「終身創始天尊指揮官」祖父條款
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
          state = state.copyWith(isPremium: false);
          return;
        }
      }

      final expiryStr = prefs.getString('expiry_date');
      final coins = prefs.getInt('captain_coins') ?? 0;

      DateTime? expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

      // 離線過期防禦（創始會員永久豁免降級）
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

      state = PremiumState(
        isPremium: isPro,
        type: SubscriptionType.values[typeIndex < SubscriptionType.values.length ? typeIndex : 0],
        expiryDate: expiryDate,
        isFounder: isFounder,
        coinBalance: coins,
      );
    } catch (e) {
      state = PremiumState(isPremium: false);
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

  Future<bool> redeemCoinsForProPass(int coins, int passDays) async {
    if (state.isFounder) return false;
    if (state.coinBalance < coins) return false;

    final bool spent = await spendCoins(coins);
    if (!spent) return false;

    final now = DateTime.now();
    final DateTime baseDate = (state.isPremium && state.expiryDate != null && state.expiryDate!.isAfter(now))
        ? state.expiryDate!
        : now;
    final DateTime newExpiry = baseDate.add(Duration(days: passDays));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);
    await prefs.setString('expiry_date', newExpiry.toIso8601String());

    final SubscriptionType newType = state.type == SubscriptionType.none 
        ? SubscriptionType.weekly 
        : state.type;
    await prefs.setInt('sub_type', newType.index);

    state = state.copyWith(
      isPremium: true,
      expiryDate: newExpiry,
      type: newType,
    );
    return true;
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
