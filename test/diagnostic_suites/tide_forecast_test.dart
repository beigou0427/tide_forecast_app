import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/tide_forecast_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('【功能 03 真實穿透自檢】未來 30 天潮汐預報空間拓撲與型別容錯解析實體審計', () async {
    final result = await TideForecastDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 03 專項自檢：30 天滿乾潮預報與型別容錯審計】       ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 快照在線 : ${result.isSnapshotLoaded ? '✅ 正常' : '❌ 缺失'} (加載 ${result.totalForecastCount} 組滿乾潮數據)");
    print("║ • 型別容錯 : ${result.isTypeTolerancePassed ? '✅ 通行' : '❌ 崩潰'} (Int / Double / String / Null 混合注入零崩潰)");
    print("║ • 預報跨度 : ${result.isTimeHorizonValid ? '✅ 合規' : '❌ 不足'} (實測覆蓋 ${result.daysCovered} 天時間軸)");
    print("║ • 滿潮定位 : ${result.isNextHighTideFound ? '✅ 精準' : '❌ 失敗'} (下一次滿潮點: ${result.nextHighTideTime})");
    print("║ • 時序物理 : ${result.isTideSequenceValid ? '✅ 自然' : '❌ 異常'} (滿潮與乾潮嚴格交替出現)");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isTypeTolerancePassed, isTrue, reason: "混合型別容錯解析必須 100% 零崩潰");
    expect(result.isSnapshotLoaded, isTrue, reason: "實體快照必須包含 forecasts 陣列");
    expect(result.isTimeHorizonValid, isTrue, reason: "預報資料時間軸跨度必須達 25~30 天");
    expect(result.isNextHighTideFound, isTrue, reason: "必須能準確定位出下一個滿潮水位");
    expect(result.isTideSequenceValid, isTrue, reason: "滿乾潮時序必須符合自然交替物理規律");
  });
}
