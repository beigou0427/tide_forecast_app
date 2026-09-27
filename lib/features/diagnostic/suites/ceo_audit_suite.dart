import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../premium/services/premium_service.dart';

class CeoAuditSuiteResult {
  final bool isOfflineExpirationSafe;
  final bool isTimeTamperingDefended;
  final String message;

  const CeoAuditSuiteResult({
    required this.isOfflineExpirationSafe,
    required this.isTimeTamperingDefended,
    required this.message,
  });
}

class CeoAuditDiagnosticSuite {
  static Future<CeoAuditSuiteResult> run() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 沙盒環境備份：記錄當前真實會員狀態，測試結束後無損還原
    final backupIsPro = prefs.getBool('is_pro');
    final backupSubType = prefs.getInt('sub_type');
    final backupExpiry = prefs.getString('expiry_date');
    final backupIsFounder = prefs.getBool('is_founder');
    final backupMigrated = prefs.getBool('has_migrated_founder');
    final backupInstallEpoch = prefs.getString('app_install_epoch');

    bool offlineExpirationSafe = false;
    bool timeTamperingDefended = false;

    try {
      // ================= 測試 1：離線過期白嫖防禦 (Offline Expiration) =================
      await prefs.setBool('has_migrated_founder', true);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.weekly.index);
      await prefs.setString('expiry_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
      await prefs.setBool('is_founder', false);

      final expiredNotifier = PremiumNotifier();
      // 等待狀態機非同步載入
      await Future.delayed(const Duration(milliseconds: 100));

      offlineExpirationSafe = expiredNotifier.state.isPremium == false &&
          expiredNotifier.state.type == SubscriptionType.none;

      // ================= 測試 2：系統時間倒撥（時光機作弊）防禦 (Time Tampering) =================
      // 將安裝時間偽造為明天，模擬使用者將手機時間撥回昨天的作弊情境
      final futureInstallTime = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      await prefs.setString('app_install_epoch', futureInstallTime);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.yearly.index);
      await prefs.setString('expiry_date', DateTime.now().add(const Duration(days: 365)).toIso8601String());

      final tamperingNotifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      timeTamperingDefended = tamperingNotifier.state.isPremium == false;

    } catch (e) {
      debugPrint("🚨 [CEO Audit] 審計流程例外: $e");
    } finally {
      // 2. 沙盒無損還原：徹底還原使用者的真實帳戶狀態，嚴禁使用 prefs.clear() 破壞資料
      if (backupIsPro != null) await prefs.setBool('is_pro', backupIsPro); else await prefs.remove('is_pro');
      if (backupSubType != null) await prefs.setInt('sub_type', backupSubType); else await prefs.remove('sub_type');
      if (backupExpiry != null) await prefs.setString('expiry_date', backupExpiry); else await prefs.remove('expiry_date');
      if (backupIsFounder != null) await prefs.setBool('is_founder', backupIsFounder); else await prefs.remove('is_founder');
      if (backupMigrated != null) await prefs.setBool('has_migrated_founder', backupMigrated); else await prefs.remove('has_migrated_founder');
      if (backupInstallEpoch != null) await prefs.setString('app_install_epoch', backupInstallEpoch); else await prefs.remove('app_install_epoch');
    }

    String msg;
    if (!offlineExpirationSafe) {
      msg = "❌ 發現資金漏洞：VIP 過期後在離線冷啟動狀態下未被強制降級！";
    } else if (!timeTamperingDefended) {
      msg = "❌ 發現時光機漏洞：系統時間回撥未能觸發強制保護！";
    } else {
      msg = "✅ 財務防線完備，離線過期降級與時鐘回撥作弊防禦全數真穿透通過。";
    }

    return CeoAuditSuiteResult(
      isOfflineExpirationSafe: offlineExpirationSafe,
      isTimeTamperingDefended: timeTamperingDefended,
      message: msg,
    );
  }
}
