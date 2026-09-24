import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/catch_log_suite.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('【功能 08 真實穿透自檢】私人潮汐漁獲私密日誌序列化保真與磁碟 CRUD 實體審計', () async {
    final result = await CatchLogDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 08 專項自檢：私人漁獲日誌資料庫與 I/O 實測】       ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 序列保真 : ${result.isSerializationLossless ? '✅ 無損' : '❌ 失真'} (Emoji / 特殊符號 / Null 浮標容錯 100% 吻合)");
    print("║ • 存儲讀寫 : ${result.isCrudPersistencePassed ? '✅ 精準' : '❌ 失敗'} (寫入 3 筆、刪除 1 筆、校驗剩餘 2 筆無損)");
    print("║ • 時間倒序 : ${result.isChronologicalSortAccurate ? '✅ 完好' : '❌ 錯亂'} (最新作釣紀錄排在最前，時序嚴格遞減)");
    print("║ • 磁碟效能 : ${result.isLatencyHealthy ? '✅ 極速' : '❌ 遲緩'} (${result.latencyMicroseconds} μs 完成全套 CRUD)");
    print("║ • 實測樣本 : ${result.sampleRecord}");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isSerializationLossless, isTrue, reason: "雙向序列化必須 100% 完整無損");
    expect(result.isCrudPersistencePassed, isTrue, reason: "CRUD 讀寫與刪除邏輯必須精確");
    expect(result.isChronologicalSortAccurate, isTrue, reason: "日誌必須按時間倒序排列");
    expect(result.isLatencyHealthy, isTrue, reason: "I/O 延遲必須維持在極速水準");
  });
}
