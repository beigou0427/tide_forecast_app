import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iap_manager.dart';

enum SubscriptionType { none, weekly, monthly, yearly, lifetime }

class PremiumState {
  final bool isPremium;
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isFounder;

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

      final bool alreadyMigrated = prefs.getBool('has_migrated_founder') ?? false;
      final bool oldIsPro = prefs.getBool('is_pro') ?? false;

      if (!alreadyMigrated && oldIsPro) {
        await prefs.setBool('is_founder', true);
        await prefs.setBool('is_pro', true);
        await prefs.setInt('sub_type', SubscriptionType.lifetime.index);
        await prefs.setString('expiry_date', DateTime(2099, 12, 31).toIso8601String());
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
          // 🚨 時光機防禦：系統時間回撥，強制封鎖
          await prefs.setBool('is_pro', false);
          await prefs.remove('expiry_date');
          await prefs.setInt('sub_type', SubscriptionType.none.index);
          state = PremiumState(isPremium: false);
          return;
        }
      }

      bool isPro = prefs.getBool('is_pro') ?? false;
      int typeIndex = prefs.getInt('sub_type') ?? 0;
      final expiryStr = prefs.getString('expiry_date');
      final isFounder = prefs.getBool('is_founder') ?? false;

      DateTime? expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

      // 🚨 離線過期白嫖防禦：過期後徹底降級
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
    if (state.isFounder) return;
    await prefs.remove('is_pro');
    await prefs.remove('sub_type');
    await prefs.remove('expiry_date');
    state = PremiumState(isPremium: false, type: SubscriptionType.none);
  }
}
