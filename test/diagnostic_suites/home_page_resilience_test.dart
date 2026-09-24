import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/home_page_resilience_suite.dart';

void main() {
  test('【功能 05 真實穿透自檢】首頁極端情境與 48 小時時空切片防紅屏死機實體審計', () async {
    final result = await HomePageResilienceDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 05 專項自檢：首頁極端情境防崩潰與切片精度】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 未來防崩 : ${result.isFutureNoElementCrashProof ? '✅ 零紅屏' : '❌ 崩潰'} (未來 30 天無實測資料時絕無 .last 異常)");
    print("║ • 歷史邊界 : ${result.isPastEmptyDaySafe ? '✅ 安全' : '❌ 失敗'} (歷史無存檔日期安全觸發無資料防禦)");
    print("║ • 今日切片 : ${result.isDateSlicingAccurate ? '✅ 精準' : '❌ 失真'} (跨日多筆時序切片精度 100% 吻合)");
    print("║ • 畸形防禦 : ${result.isMalformedStationSafe ? '✅ 零閃退' : '❌ 閃退'} (全空測站物件屬性讀取安全)");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isFutureNoElementCrashProof, isTrue, reason: "未來預報模式下嚴禁拋出 Bad state: No element 崩潰");
    expect(result.isPastEmptyDaySafe, isTrue, reason: "歷史無資料日必須安全過濾為 null");
    expect(result.isDateSlicingAccurate, isTrue, reason: "今日切片必須精準排除昨日資料並鎖定最新數值");
    expect(result.isMalformedStationSafe, isTrue, reason: "全空測站物件必須安全解析");
  });
}
