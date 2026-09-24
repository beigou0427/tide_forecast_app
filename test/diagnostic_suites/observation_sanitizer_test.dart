import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/observation_sanitizer_suite.dart';

void main() {
  test('【功能 04 真實穿透自檢】水文實測髒數據清洗、極值邊界與空值容錯實體審計', () async {
    final result = await ObservationSanitizerDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 04 專項自檢：水文觀測髒數據清洗與型態安全】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 雜訊清洗 : ${result.isDirtyStringCleaned ? '✅ 成功' : '❌ 失敗'} (-99 / None / nan / null 安全轉為 null)");
    print("║ • 數值提取 : ${result.isExtremeNoiseFiltered ? '✅ 正常' : '❌ 異常'} (高低極限浮點數提取無例外)");
    print("║ • 精度保留 : ${result.isNormalPrecisionRetained ? '✅ 無損' : '❌ 失真'} (正常水溫/氣壓/潮高數值零精度丟失)");
    print("║ • 空值防禦 : ${result.isEmptyJsonCrashProof ? '✅ 零崩潰' : '❌ 崩潰'} (全空畸形 JSON 注入零閃退)");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isDirtyStringCleaned, isTrue, reason: "髒數據必須安全清洗為 null，絕不拋 FormatException");
    expect(result.isExtremeNoiseFiltered, isTrue, reason: "數值提取邏輯必須健全");
    expect(result.isNormalPrecisionRetained, isTrue, reason: "正常數值必須 100% 保留小數點精確度");
    expect(result.isEmptyJsonCrashProof, isTrue, reason: "全空 JSON 物件嚴禁拋出未捕獲崩潰");
  });
}
