import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/cwa_auth_suite.dart';

void main() {
  // 開啟實體網路連線權限，允許向氣象署發送真實 HTTP 封包
  setUpAll(() => HttpOverrides.global = null);

  test('【功能 01 真實穿透自檢】CWA 金鑰安全解密與官方伺服器即時鑑權', () async {
    final result = await CwaAuthDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 01 專項自檢：CWA 官方金鑰解密與伺服器鑑權】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 解密狀態 : ${result.isDecrypted ? '✅ 成功' : '❌ 失敗'} (${result.maskedKey})");
    print("║ • UUID 格式: ${result.isRegexValid ? '✅ 合規' : '❌ 損壞'} (RFC 4122 標準)");
    print("║ • 官方鑑權 : ${result.isServerAuthorized ? '✅ 通行' : '❌ 拒絕'} (HTTP ${result.httpStatusCode} • ${result.latencyMs} ms)");
    print("║ • 診斷細節 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    // 三道硬核斷言：任一項失敗直接噴紅燈
    expect(result.isDecrypted, isTrue, reason: "XOR 位元組解密必須成功");
    expect(result.isRegexValid, isTrue, reason: "金鑰必須符合 CWA 官方 UUID 格式");
    expect(result.isServerAuthorized, isTrue, reason: "氣象署官方伺服器必須回傳 HTTP 200");
  });
}
