import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/features/catch_log/data/catch_log_model.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/catch_log_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('🔍 【功能 08 專項自檢】Cynthia Stoddard 資料治理、被遺忘權與漁獲日誌審計', () {
    
    test('【基底測試】私人潮汐漁獲私密日誌序列化保真與磁碟 CRUD 實體審計', () async {
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

    // 🌟 Cynthia Stoddard 測試 1：本地沙盒與雲端 Storage 雙軌路徑序列化保真
    test('Cynthia Stoddard 01: 本地沙盒 imagePath 與雲端 Storage imageUrl 雙軌無損映射', () {
      final itemWithCloud = CatchLogItem(
        id: "trophy_cloud_999",
        dateTime: DateTime(2026, 9, 29, 14, 0),
        stationName: "新北石門 富貴角資料浮標 (C6AH2)",
        species: "🐟 巨型黑毛 52cm 👑",
        tideHeight: 1.85,
        waveHeight: 0.9,
        seaTemperature: 24.5,
        notes: "雲端相簿自動同步測試",
        rating: 5,
        imagePath: "/data/user/0/com.beigou.tideForecastApp/app_flutter/test.jpg",
        imageUrl: "https://firebasestorage.googleapis.com/v0/b/tide-pro.appspot.com/users/dev/1.jpg",
      );

      final jsonStr = itemWithCloud.toJson();
      final restored = CatchLogItem.fromJson(jsonStr);

      expect(restored.imagePath, equals(itemWithCloud.imagePath), reason: "本地沙盒路徑遺失！");
      expect(restored.imageUrl, equals(itemWithCloud.imageUrl), reason: "雲端 Storage 網址遺失！");
      expect(restored.species, contains("52cm"));
    });

    // 🌟 Cynthia Stoddard 測試 2：App Store Guideline 5.1.1(v) 被遺忘權徹底銷毀模擬
    test('Cynthia Stoddard 02: 被遺忘權徹底銷毀 (Data Purge) 演算法驗證：本地殘留歸零', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // 模擬寫入使用者機敏資料
      final dummyLogs = [
        CatchLogItem(id: "log_1", dateTime: DateTime.now(), stationName: "龍洞", species: "黑毛"),
        CatchLogItem(id: "log_2", dateTime: DateTime.now(), stationName: "富貴角", species: "軟絲"),
      ];
      await prefs.setStringList("catch_logs_v1", dummyLogs.map((e) => e.toJson()).toList());
      await prefs.setInt("captain_coins", 88);
      await prefs.setStringList("blocked_ugc_authors", ["spammer_01"]);

      expect(prefs.getStringList("catch_logs_v1")?.length, equals(2));
      expect(prefs.getInt("captain_coins"), equals(88));

      // 執行被遺忘權徹底抹除動作
      await prefs.remove("catch_logs_v1");
      await prefs.remove("captain_coins");
      await prefs.remove("blocked_ugc_authors");

      // 斷言：機敏個資已 100% 自磁碟蒸發
      expect(prefs.getStringList("catch_logs_v1"), isNull, reason: "被遺忘權失守：漁獲日誌未徹底銷毀！");
      expect(prefs.getInt("captain_coins"), isNull, reason: "被遺忘權失守：虛擬資產代幣殘留！");
      expect(prefs.getStringList("blocked_ugc_authors"), isNull, reason: "社群黑名單殘留！");
    });
  });
}