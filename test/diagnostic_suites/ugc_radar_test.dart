import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/ugc_radar_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('【功能 09 真實穿透自檢】釣魚版 Waze 實況雷達、AI 哨兵動態決策與通報送 Pro 閉環', (WidgetTester tester) async {
    UgcRadarSuiteResult? result;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await UgcRadarDiagnosticSuite.run(ref);
                  },
                  child: const Text('RUN_DIAGNOSTIC'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(result, isNotNull, reason: "自檢套件必須正常執行並回傳診斷結果");
    final r = result!;

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 09 專項自檢：Waze 實況雷達與 AI 哨兵閉環】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 標籤結構 : ${r.is6TagsStructureValid ? '✅ 完整' : '❌ 損壞'} (6 大水文標籤 JSON 序列化雙向保真)");
    print("║ • 哨兵補位 : ${r.isColdStartSentinelWorking ? '✅ 成功' : '❌ 失敗'} (0 人回報時 AI 哨兵 1ms 自動補位)");
    print("║ • 實況決策 : ${r.isDynamicWaveRuleAccurate ? '✅ 精準' : '❌ 偏差'} (大浪2.5m觸發偏大、小浪0.6m觸發平穩)");
    print("║ • 激勵閉環 : ${r.isProIncentiveStateFlipped ? '✅ 暢通' : '❌ 失敗'} (通報實況即刻觸發 Pro 特權狀態流轉)");
    print("║ • 時效過濾 : ${r.is6HourExpiryFilterValid ? '✅ 完好' : '❌ 洩漏'} (7 小時過期情報 100% 自動清洗)");
    print("║ • 哨兵樣本 : ${r.sentinelSample}");
    print("║ • 審計結論 : ${r.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(r.is6TagsStructureValid, isTrue, reason: "6 大實況標籤資料結構必須 100% 吻合");
    expect(r.isColdStartSentinelWorking, isTrue, reason: "無人回報時 AI 哨兵必須立刻補位，絕不留白");
    expect(r.isDynamicWaveRuleAccurate, isTrue, reason: "大浪與小浪之哨兵動態決策規則必須精準");
    expect(r.isProIncentiveStateFlipped, isTrue, reason: "通報實況必須能真實驅動會員狀態流轉");
    expect(r.is6HourExpiryFilterValid, isTrue, reason: "超過 6 小時之情報必須強制過濾");
  });
}
