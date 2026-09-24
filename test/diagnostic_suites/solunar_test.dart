import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/solunar_suite.dart';

void main() {
  test('【功能 06 真實穿透自檢】月相農曆・大潮小潮與咬度算盤 365 天軌道壓測', () async {
    final result = await SolunarDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 06 專項自檢：月相農曆與大潮小潮咬度算盤】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 軌道壓測 : ${result.is365DaysOrbitPassed ? '✅ 通行' : '❌ 溢出'} (連續遍歷 365 天全週期零溢出)");
    print("║ • 水文定律 : ${result.isTidalRulesAccurate ? '✅ 精確' : '❌ 偏離'} (初一十五大潮、初八小潮、初十長潮 100% 吻合)");
    print("║ • 農曆正則 : ${result.isLunarRegexValid ? '✅ 合規' : '❌ 異常'} (365 天字串全數通過繁體正規語法)");
    print("║ • 跨代混沌 : ${result.isExtremeEpochSafe ? '✅ 健全' : '❌ 崩潰'} (1970~2099 年跨世紀運算零閃退)");
    print("║ • 今日實況 : ${result.sampleDate} ➔ ${result.sampleLunar} • ${result.samplePhase} • ${result.sampleTide} • 咬度 ${result.sampleScore}%");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.is365DaysOrbitPassed, isTrue, reason: "365 天全軌道運算嚴禁有任何一天數值溢出");
    expect(result.isTidalRulesAccurate, isTrue, reason: "大中小潮必須嚴格遵守海洋物理定律");
    expect(result.isLunarRegexValid, isTrue, reason: "農曆字串必須 100% 通過正則表達式語法校驗");
    expect(result.isExtremeEpochSafe, isTrue, reason: "跨世紀極端時間戳嚴禁崩潰");
  });
}
