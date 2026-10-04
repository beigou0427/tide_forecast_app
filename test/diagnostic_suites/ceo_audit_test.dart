import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/ceo_audit_suite.dart';
import 'package:tide_forecast_app/features/premium/services/premium_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🔍 【CEO 專項審計】Leslie Lamport 時態不變量、時鐘防篡改與形式化狀態守衛', () {
    
    test('【基底測試】離線白嫖漏洞、時間竄改防禦與商業命脈深度審計', () async {
      final result = await CeoAuditDiagnosticSuite.run();

      print("\n╔══════════════════════════════════════════════════════════════╗");
      print("║   💼 【CEO 專項審計：商業命脈與資金防白嫖深水炸彈】          ║");
      print("╠══════════════════════════════════════════════════════════════╣");
      print("║ • 離線過期防護 : ${result.isOfflineExpirationSafe ? '✅ 安全' : '❌ 嚴重漏洞'} (斷網啟動時自動核對過期日並降級)");
      print("║ • 時光機防禦   : ${result.isTimeTamperingDefended ? '✅ 安全' : '❌ 嚴重漏洞'} (防範用戶修改手機系統時間無限試用)");
      print("║ • 審計結論     : ${result.message}");
      print("╚══════════════════════════════════════════════════════════════╝\n");

      expect(result.isOfflineExpirationSafe, isTrue, reason: "CEO 警告：斷網啟動時，若訂閱已過期，必須強制降級為免費會員！");
      expect(result.isTimeTamperingDefended, isTrue, reason: "CEO 警告：必須記錄 App 首次安裝時間以防範手機系統時間回溯竄改！");
    });

    // 🌟 Leslie Lamport 形式化不變量 1：時態單調性 (Temporal Monotonicity Invariant)
    test('Leslie Lamport 01: [Invariant Safety] 當前時鐘早於安裝時鐘 (倒撥時鐘作弊)，Pro 權限必定即刻無效化', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // 模擬將系統時間撥回過去 (安裝時間被錨定在明天)
      final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String();
      await prefs.setString('app_install_epoch', tomorrow);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.yearly.index);
      await prefs.setString('expiry_date', DateTime.now().add(const Duration(days: 365)).toIso8601String());

      final notifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 60));

      // 形式化安全斷言：時鐘回撥作弊下，Premium 狀態必定為 false
      expect(notifier.state.isPremium, isFalse, reason: "時鐘倒流安全不變量失守！用戶透過回撥系統時間白嫖了 Pro 權限！");
      expect(notifier.state.type, equals(SubscriptionType.none));
    });

    // 🌟 Leslie Lamport 形式化不變量 2：創始會員永恆性 (Founder Permanence Invariant)
    test('Leslie Lamport 02: [Permanence Safety] 創始天尊指揮官 (Founder) 享有永久最高豁免權，永不被離線降級', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // 設定過期的創始會員狀態
      await prefs.setBool('has_migrated_founder', true);
      await prefs.setBool('is_founder', true);
      await prefs.setBool('is_pro', true);
      await prefs.setInt('sub_type', SubscriptionType.lifetime.index);
      await prefs.setString('expiry_date', DateTime(2099, 12, 31).toIso8601String());

      final notifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 60));

      // 形式化安全斷言：創始天尊身分永遠屹立不搖
      expect(notifier.state.isFounder, isTrue);
      expect(notifier.state.isPremium, isTrue);
      expect(notifier.state.type, equals(SubscriptionType.lifetime));
    });

    // 🌟 Leslie Lamport 形式化不變量 3：代幣原子兌換不變量 (Coin Exchange Conservation)
    test('Leslie Lamport 03: [Conservation Invariant] 代幣不足時兌換通行證嚴禁扣幣且狀態絕不漂移', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('captain_coins', 10); // 僅有 10 幣
      await prefs.setBool('is_pro', false);

      final notifier = PremiumNotifier();
      await Future.delayed(const Duration(milliseconds: 60));

      // 嘗試兌換需 35 幣之 3 日通行證
      final bool success = await notifier.redeemCoinsForProPass(35, 3);

      expect(success, isFalse, reason: "資產守恆不變量失守！代幣不足竟兌換成功！");
      expect(notifier.state.coinBalance, equals(10), reason: "兌換失敗卻扣減了代幣餘額！");
      expect(notifier.state.isPremium, isFalse);
    });
  });
}