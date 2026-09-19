import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

/// 1. 擴充訂閱類型 (新增週費犧牲打、終身買斷)
enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

/// 2. Premium 狀態模型 (新增創始釣友標記)
class PremiumState {
  final bool isPremium;
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isFounder; // 🌟 創始天使標記

  PremiumState({
    required this.isPremium,
    this.type = SubscriptionType.none,
    this.expiryDate,
    this.isFounder = false,
  });

  Map<String, dynamic> toJson() => {
    'isPremium': isPremium,
    'type': type.index,
    'expiryDate': expiryDate?.toIso8601String(),
    'isFounder': isFounder,
  };
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

      // 🌟【創始天使防禦遷移邏輯】
      // 檢查改版前原本已經是 is_pro 的老用戶，直接封頂為終身創始天使
      final bool alreadyMigrated = prefs.getBool('has_migrated_founder') ?? false;
      final bool oldIsPro = prefs.getBool('is_pro') ?? false;

      if (!alreadyMigrated && oldIsPro) {
        await prefs.setBool('is_founder', true);
        await prefs.setBool('is_pro', true);
        await prefs.setInt('sub_type', SubscriptionType.lifetime.index);
        await prefs.setString('expiry_date', DateTime(2099, 12, 31).toIso8601String());
        await prefs.setBool('has_migrated_founder', true);
      }

      final isPro = prefs.getBool('is_pro') ?? false;
      final typeIndex = prefs.getInt('sub_type') ?? 0;
      final expiryStr = prefs.getString('expiry_date');
      final isFounder = prefs.getBool('is_founder') ?? false;

      state = PremiumState(
        isPremium: isPro,
        type: SubscriptionType.values[typeIndex < SubscriptionType.values.length ? typeIndex : 0],
        expiryDate: expiryStr != null ? DateTime.tryParse(expiryStr) : null,
        isFounder: isFounder,
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

    state = PremiumState(
      isPremium: isPro,
      type: type,
      expiryDate: expiry,
      isFounder: state.isFounder,
    );
  }

  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    // 創始天使不允許被撤銷
    if (state.isFounder) return;
    
    await prefs.clear();
    state = PremiumState(isPremium: false, type: SubscriptionType.none);
  }
}

