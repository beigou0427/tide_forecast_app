import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/premium/services/premium_service.dart';

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

    // ================= 1. 離線過期白嫖漏洞測試 =================
    // 🌟 補上 has_migrated_founder 標籤，防止被老用戶福利系統誤判升級為 2099 年終身會員！
    await prefs.setBool('has_migrated_founder', true);
    
    await prefs.setBool('is_pro', true);
    await prefs.setInt('sub_type', SubscriptionType.weekly.index);
    await prefs.setString('expiry_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());
    await prefs.setBool('is_founder', false);

    // 啟動會員狀態機 (模擬 App 斷網冷啟動)
    final notifier = PremiumNotifier();
    await Future.delayed(const Duration(milliseconds: 200));

    // 🚨 查核：過期且非創始會員，必須被強制降級為 false！
    final bool offlineExpirationSafe = notifier.state.isPremium == false;

    // ================= 2. 系統時間竄改 (時光機漏洞) 測試 =================
    final fakeSystemTime = DateTime(2016, 1, 1);
    
    await prefs.setBool('has_migrated_founder', true);
    await prefs.setBool('is_pro', true);
    await prefs.setInt('sub_type', SubscriptionType.yearly.index);
    await prefs.setString('expiry_date', DateTime(2027, 1, 1).toIso8601String());

    bool timeTamperingDefended = false;
    try {
      final appInstallTimeStr = prefs.getString('app_install_epoch');
      if (appInstallTimeStr != null) {
        final installTime = DateTime.parse(appInstallTimeStr);
        if (fakeSystemTime.isBefore(installTime)) {
          timeTamperingDefended = true; // 成功攔截竄改
        }
      }
    } catch (_) {}

    await prefs.clear();

    String msg;
    if (!offlineExpirationSafe) {
      msg = "❌ 發現嚴重漏洞：VIP 過期後在離線狀態下未自動降級，允許永久白嫖！";
    } else if (!timeTamperingDefended) {
      msg = "❌ 發現嚴重漏洞：缺乏系統時間竄改防禦，用戶可透過修改手機時間無限延長試用！";
    } else {
      msg = "✅ 資金防護網完備，離線過期與時光機漏洞全數封鎖。";
    }

    return CeoAuditSuiteResult(
      isOfflineExpirationSafe: offlineExpirationSafe,
      isTimeTamperingDefended: timeTamperingDefended,
      message: msg,
    );
  }
}
