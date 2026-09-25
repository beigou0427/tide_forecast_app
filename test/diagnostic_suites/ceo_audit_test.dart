import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/ceo_audit_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('【CEO 資金防漏大審計】離線白嫖漏洞、時間竄改防禦與 API DDoS 風險實測', () async {
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
}
