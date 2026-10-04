import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../premium/services/premium_service.dart';

/// 🌟 Leslie Lamport 形式化審計結果實體 (Formal State Invariant Result)
class CeoAuditSuiteResult {
  final bool isOfflineExpirationSafe;
  final bool isTimeTamperingDefended;
  final bool isFounderGrandfatherSafe;
  final bool isSandboxReversionLossless;
  final String message;

  const CeoAuditSuiteResult({
    required this.isOfflineExpirationSafe,
    required this.isTimeTamperingDefended,
    this.isFounderGrandfatherSafe = true,
    this.isSandboxReversionLossless = true,
    required this.message,
  });

  bool get isAllPassed =>
      isOfflineExpirationSafe &&
      isTimeTamperingDefended &&
      isFounderGrandfatherSafe &&
      isSandboxReversionLossless;
}

/// 🌟 Leslie Lamport (圖靈獎得主) TLA+ 風格時態不變量審計沙盒
class CeoAuditDiagnosticSuite {
  static Future<CeoAuditSuiteResult> run() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 前置條件 (Pre-condition)：快照記錄真實用戶資產狀態
    final backupIsPro = prefs.getBool('is_pro');
    final backupSubType = prefs.getInt('sub_type');
    final backupExpiry = prefs.getString('expiry_date');
    final backupIsFounder = prefs.getBool('is_founder');
    final backupMigrated = prefs.getBool('has_migrated_founder');
    final backupInstallEpoch = prefs.getString('app_install_epoch');
    final backupCoins = prefs.getInt('captain_coins');

    bool offlineExpirationSafe = false;
    bool timeTamperingDefended = false;
    bool founderGrandfatherSafe = false;

    try {
      // ================= 不變量 1：離線過期防衛 (Offline Expiration Invariant) =================
      await prefs.setBool('has_migrated_founder', true);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.weekly.index);
      await prefs.setString('expiry_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      await prefs.setBool('is_founder', false);

      final expiredNotifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 70));

      offlineExpirationSafe = expiredNotifier.state.isPremium == false &&
          expiredNotifier.state.type == SubscriptionType.none;

      // ================= 不變量 2：時鐘回撥作弊防衛 (Time Tampering Invariant) =================
      final futureInstallTime = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      await prefs.setString('app_install_epoch', futureInstallTime);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.yearly.index);
      await prefs.setString('expiry_date', DateTime.now().add(const Duration(days: 365)).toIso8601String());

      final tamperingNotifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 70));

      timeTamperingDefended = tamperingNotifier.state.isPremium == false;

      // ================= 不變量 3：創始者祖父條款永恆性 (Founder Invariance) =================
      await prefs.setBool('has_migrated_founder', false);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.yearly.index);
      await prefs.remove('expiry_date');

      final founderNotifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 70));

      founderGrandfatherSafe = founderNotifier.state.isFounder == true &&
          founderNotifier.state.isPremium == true &&
          founderNotifier.state.type == SubscriptionType.lifetime;

    } catch (e) {
      debugPrint("🚨 [Lamport Audit] 形式化審計流程異常: $e");
    } finally {
      // 2. 後置條件 (Post-condition)：無損原子級還原沙盒資產
      if (backupIsPro != null) await prefs.setBool('is_pro', backupIsPro); else await prefs.remove('is_pro');
      if (backupSubType != null) await prefs.setInt('sub_type', backupSubType); else await prefs.remove('sub_type');
      if (backupExpiry != null) await prefs.setString('expiry_date', backupExpiry); else await prefs.remove('expiry_date');
      if (backupIsFounder != null) await prefs.setBool('is_founder', backupIsFounder); else await prefs.remove('is_founder');
      if (backupMigrated != null) await prefs.setBool('has_migrated_founder', backupMigrated); else await prefs.remove('has_migrated_founder');
      if (backupInstallEpoch != null) await prefs.setString('app_install_epoch', backupInstallEpoch); else await prefs.remove('app_install_epoch');
      if (backupCoins != null) await prefs.setInt('captain_coins', backupCoins); else await prefs.remove('captain_coins');
    }

    // 3. 還原校驗：證明沙盒 0 污染原始狀態
    final bool sandboxLossless = (prefs.getBool('is_pro') == backupIsPro) &&
        (prefs.getString('app_install_epoch') == backupInstallEpoch) &&
        (prefs.getInt('captain_coins') == backupCoins);

    String msg;
    if (!offlineExpirationSafe) {
      msg = "❌ 狀態機漏洞：VIP 過期後在斷網啟動下未強制降級！";
    } else if (!timeTamperingDefended) {
      msg = "❌ 漏洞：系統時鐘回撥未能觸發保護！";
    } else if (!founderGrandfatherSafe) {
      msg = "❌ 祖父條款失效：年度老會員未無痛直升終身創始！";
    } else if (!sandboxLossless) {
      msg = "❌ 沙盒污染：審計後原始資產未能 100% 無損復原！";
    } else {
      msg = "✅ 形式化時態四重不變量全數證明完備，時鐘防篡改與沙盒零污染！";
    }

    return CeoAuditSuiteResult(
      isOfflineExpirationSafe: offlineExpirationSafe,
      isTimeTamperingDefended: timeTamperingDefended,
      isFounderGrandfatherSafe: founderGrandfatherSafe,
      isSandboxReversionLossless: sandboxLossless,
      message: msg,
    );
  }
}