import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/tts_suite.dart';

void main() {
  test('【功能 10 真實穿透自檢】老船長語音海象晨報 TTS 語料合成、空值防護與時間軸實體審計', () async {
    final result = await TtsDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 10 專項自檢：老船長語音晨報 TTS 語料與防護】      ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 空值防禦 : ${result.isEmptyStationCrashProof ? '✅ 零崩潰' : '❌ 崩潰'} (全空/斷線測站注入，無 null 且安全生成)");
    print("║ • 語料飽滿 : ${result.isFullScriptIntegrityPassed ? '✅ 完整' : '❌ 殘缺'} (${result.fullScriptLength} 字元 • 站名/浪高/海溫/風速全齊)");
    print("║ • 滿潮口語 : ${result.isNextHighTideTimeFormatted ? '✅ 精準' : '❌ 格式錯誤'} (精準轉譯為「HH點mm分」口語時間)");
    print("║ • 聲學規範 : ${result.isAcousticParametersValid ? '✅ 合規' : '❌ 異常'} (zh-TW 繁中 • 0.5 沉穩語速 • 0.95 船長音色)");
    print("║ • 完整語料範例 : ");
    print("║   「${result.sampleFullScript}」");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isEmptyStationCrashProof, isTrue, reason: "空測站嚴禁拋錯或在語音中唸出 null");
    expect(result.isFullScriptIntegrityPassed, isTrue, reason: "完整測站必須具備完整水文參數");
    expect(result.isNextHighTideTimeFormatted, isTrue, reason: "滿潮時間必須轉化為口語 HH點mm分 格式");
    expect(result.isAcousticParametersValid, isTrue, reason: "聲學配置必須完全符合 zh-TW 規範");
  });
}
