import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/wind_compass_suite.dart';

void main() {
  test('【功能 07 真實穿透自檢】360° 航海作戰羅盤負角度防溢出與蒲福風級全階梯實測', () async {
    final result = await WindCompassDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 07 專項自檢：360° 航海作戰羅盤與風級換算】       ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 負角防溢 : ${result.isNegativeAnglesSafe ? '✅ 零越界' : '❌ 越界崩潰'} (-720° ~ 1080° 極值防溢出 100% 通過)");
    print("║ • 方位映射 : ${result.is16DirectionsAccurate ? '✅ 精準' : '❌ 偏離'} (0°:${result.sample0Deg} • 67.5°:${result.sample67Deg} • 180°:${result.sample180Deg} • 270°:${result.sample270Deg})");
    print("║ • 蒲福風級 : ${result.isBeaufortScaleAccurate ? '✅ 吻合' : '❌ 失真'} (0 級無風至 8+ 級大風階梯完全吻合)");
    print("║ • 戰術指引 : ${result.isTacticalAdviceValid ? '✅ 就緒' : '❌ 缺失'} (輕風阿波、推浪換重鉛、大風防吹落戰術連動)");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isNegativeAnglesSafe, isTrue, reason: "負角度與超界方位角嚴禁拋出 RangeError 索引越界");
    expect(result.is16DirectionsAccurate, isTrue, reason: "16 方位角名稱必須精準符合海事標準");
    expect(result.isBeaufortScaleAccurate, isTrue, reason: "蒲福風力等級換算必須 100% 吻合國際標準");
    expect(result.isTacticalAdviceValid, isTrue, reason: "各風級戰術指引必須完整");
  });
}
