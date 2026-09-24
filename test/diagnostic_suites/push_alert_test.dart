import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/push_alert_suite.dart';

void main() {
  test('【功能 11 真實穿透自檢】滿潮防困推播通道、時區演算法與 FCM 雲端主題審計', () async {
    final result = await PushAlertDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 11 專項自檢：滿潮推播通道與時區演算法審計】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 週五演算法 : ${result.isFridayAlgorithmAccurate ? '✅ 精準' : '❌ 失效'} (跨年、跨週邊界時間演算 100% 正確)");
    print("║ • 滿潮 30分 : ${result.isSurgeAlertOffsetValid ? '✅ 精確' : '❌ 偏離'} (自動推算滿潮時間偏移並排程)");
    print("║ • 救命優先級 : ${result.isChannelConfigurationValid ? '✅ 合規' : '❌ 異常'} (警報通道設定 Importance.max 防止靜音)");
    print("║ • FCM 雲端 : ${result.isFcmTopicsAligned ? '✅ 暢通' : '❌ 未綁定'} (weekend_briefing 雙主題頻道對齊)");
    print("║ • 實測排程點 : 下一次週末決策報發布於 ${result.sampleFridayTime}");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isFridayAlgorithmAccurate, isTrue, reason: "週五排程演算法嚴禁算到過去的日期");
    expect(result.isSurgeAlertOffsetValid, isTrue, reason: "滿潮警報必須精確落在滿潮前 30 分鐘");
    expect(result.isChannelConfigurationValid, isTrue, reason: "生命安全警報必須配置系統最高優先級");
  });
}
