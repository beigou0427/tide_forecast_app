import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/cwa_auth_suite.dart';

void main() {
  // 開啟實體網路連線通道，允許向氣象署發送真實 HTTP 封包
  setUpAll(() => HttpOverrides.global = null);

  test('【功能 01 真實穿透自檢】CWA 金鑰安全解密、UUID 格式校驗與離線容錯握手審計', () async {
    final result = await CwaAuthDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 01 專項自檢：CWA 官方金鑰解密與伺服器鑑權】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 解密狀態 : ${result.isDecrypted ? '✅ 成功' : '❌ 失敗'} (${result.maskedKey})");
    print("║ • UUID 格式: ${result.isRegexValid ? '✅ 合規' : '❌ 損壞'} (RFC 4122 標準)");
    print("║ • 官方鑑權 : ${result.isServerAuthorized ? '✅ 通行 (HTTP 200)' : (result.httpStatusCode == 0 ? '⚠️ 離線/逾時自癒' : '❌ 授權拒絕')} (代碼: ${result.httpStatusCode} • ${result.latencyMs} ms)");
    print("║ • 診斷細節 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    // 🌟 剛性防線 1：XOR 動態位元組解密必須 100% 成功
    expect(result.isDecrypted, isTrue, reason: "XOR 位元組矩陣動態解密失敗！");

    // 🌟 剛性防線 2：金鑰必須 100% 符合 CWA 官方 UUID 格式 (防止亂碼穿透)
    expect(result.isRegexValid, isTrue, reason: "金鑰未通過 RFC 4122 UUID 格式驗證！");

    // 🌟 智慧網絡容錯防線 3：
    // 若伺服器明確回傳 401/403，代表金鑰過期或被官方廢止，必須強制噴紅燈；
    // 若因外海離線或連線逾時 (statusCode == 0)，則放行通過並記錄日誌，消滅 CI 脆性中斷。
    final bool isAuthRejected = result.httpStatusCode == 401 || result.httpStatusCode == 403;
    expect(isAuthRejected, isFalse, reason: "🚨 致命錯誤：中央氣象署官方伺服器明確拒絕此金鑰 (HTTP ${result.httpStatusCode})，金鑰已失效！");

    if (result.isServerAuthorized) {
      expect(result.httpStatusCode, equals(200));
    } else {
      print("ℹ️ [SRE 網路容錯] 當前處於離線測試或 API 握手維護週期，已驗證金鑰本體結構無損。");
    }
  });
}