import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

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
  int get hashCode => Object.hash(isPremium, type, expiryDate, isFounder, coinBalance);
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
      }

      final now = DateTime.now();
      String? installStr = prefs.getString('app_install_epoch');
      if (installStr == null) {
        installStr = now.toIso8601String();
        await prefs.setString('app_install_epoch', installStr);
      } else {
        final installTime = DateTime.parse(installStr);
        if (now.isBefore(installTime.subtract(const Duration(minutes: 5)))) {
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

  // 🌟 核心升級：接收 IAPManager 傳入的真實精算到期日 (exactExpiry)
  Future<void> setPremiumStatus(bool isPro, SubscriptionType type, {DateTime? exactExpiry}) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? expiry;
    bool targetFounderState = state.isFounder;

    if (isPro) {
      if (exactExpiry != null) {
        expiry = exactExpiry;
        if (type == SubscriptionType.lifetime) targetFounderState = true;
      } else {
        final now = DateTime.now();
        switch (type) {
          case SubscriptionType.weekly: expiry = now.add(const Duration(days: 7)); break;
          case SubscriptionType.monthly: expiry = now.add(const Duration(days: 30)); break;
          case SubscriptionType.yearly: expiry = now.add(const Duration(days: 365)); break;
          case SubscriptionType.lifetime: expiry = DateTime(2099, 12, 31); targetFounderState = true; break;
          default: expiry = null;
        }
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

  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.isFounder) return; 
    
    await prefs.remove('is_pro');
    await prefs.remove('sub_type');
    await prefs.remove('expiry_date');
    state = state.copyWith(isPremium: false, type: SubscriptionType.none);
  }
}