import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/core/utils/constants.dart';
import 'package:tide_forecast_app/features/catch_log/data/catch_log_model.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('【反作弊深水炸彈實測】全域盲區、ID撞庫、全欄位-99清洗與100筆日誌巨量壓測', () async {
    print("\n╔══════════════════════════════════════════════════════════════════════╗");
    print("║     💣 【全系統極限反作弊・深水炸彈盲區審計報告 (質疑可靠度專項)】      ║");
    print("╠══════════════════════════════════════════════════════════════════════╣");

    // ================= 1. 85 測站 ID 唯一性 Hash 撞庫與 8 大免費站雙向交集 =================
    final cfgFile = File('assets/stations_config.json');
    final List stationsList = jsonDecode(await cfgFile.readAsString());
    
    final stationIds = stationsList.map((s) => s['id'].toString()).toList();
    final uniqueIds = stationIds.toSet();
    final bool noDuplicateIds = stationIds.length == uniqueIds.length && uniqueIds.length == 85;

    // 8 大免費港口必須 100% 存在於唯一集合中
    final missingFreeIds = AppConstants.freeStationIds.difference(uniqueIds);
    final bool freeStationsAllPresent = missingFreeIds.isEmpty;

    final bool test1Ok = noDuplicateIds && freeStationsAllPresent;
    print("║ • 01. 85 站 ID 唯一性與免費港交集: ${test1Ok ? '✅ 零重複' : '❌ 嚴重漏洞'} (唯一ID: ${uniqueIds.length}/85 • 免費港缺失: $missingFreeIds)");

    // ================= 2. 風向、週期、流速、海溫全欄位 -99 / -999 徹底清洗審計 =================
    final allDirtyMap = {
      'DateTime': DateTime.now().toIso8601String(),
      'WeatherElements': {
        'TideHeight': '-999',
        'WaveHeight': '-99.0',
        'WindSpeed': '-999.0',
        'WavePeriod': '-99',
        'SeaTemperature': '-999',
        'CurrentSpeed': '-99',
        'WindDirection': '-999',
        'AirTemperature': '-99',
        'AirPressure': '-999'
      }
    };
    final obs = Observation.fromProxy(allDirtyMap);
    final bool allCleaned = obs.tideHeight == null &&
        obs.waveHeight == null &&
        obs.windSpeed == null &&
        obs.wavePeriod == null &&
        obs.seaTemperature == null &&
        obs.currentSpeed == null &&
        obs.windDirection == null &&
        obs.airTemperature == null &&
        obs.airPressure == null;

    print("║ • 02. 全水文欄位 -99/-999 徹底清洗 : ${allCleaned ? '✅ 零遺漏' : '❌ 存在漏網'} (風向/週期/流速/海溫全部乾淨歸零)");

    // ================= 3. 實測所有參數「全為 null」極限空海況安全防護 =================
    final nullObs = Observation(dateTime: DateTime.now());
    // 驗證屬性讀取不會引發空指針崩潰
    final bool nullSafetyOk = nullObs.waveHeight == null &&
        nullObs.windSpeed == null &&
        nullObs.tideHeight == null &&
        nullObs.windDirection == null;
    print("║ • 03. 全 null 觀測物件空指針防禦   : ${nullSafetyOk ? '✅ 零崩潰' : '❌ 崩潰'} (極端無感測資料物件讀取安全)");

    // ================= 4. 漁獲日誌 100 筆大量資料巨量壓測 (Volume Stress Test) =================
    final prefs = await SharedPreferences.getInstance();
    final sw = Stopwatch()..start();
    final List<CatchLogItem> heavyList = [];
    final baseTime = DateTime.now();

    for (int i = 0; i < 100; i++) {
      heavyList.add(CatchLogItem(
        id: "heavy_log_$i",
        dateTime: baseTime.subtract(Duration(hours: i * 2)), // 時間遞減
        stationName: i % 2 == 0 ? "新北石門 富貴角資料浮標 (C6AH2)" : "新北貢寮 龍洞資料浮標 (46694A)",
        species: "🐟 大黑毛 #$i 號 (體長 ${40 + (i % 15)}cm) 🌊",
        tideHeight: 1.5 + (i % 10) * 0.1,
        waveHeight: 0.8 + (i % 5) * 0.2,
        seaTemperature: 24.0 + (i % 4) * 0.5,
        notes: "這是第 $i 筆高強度測試備忘錄，包含長文本與表情符號 🎯🎣 測試大數據量下 JSON 存取性能與記憶體表現。",
        rating: (i % 5) + 1,
      ));
    }

    // 實測寫入 100 筆
    await prefs.setStringList("heavy_stress_key", heavyList.map((e) => e.toJson()).toList());
    
    // 實測讀取 100 筆並執行時間倒序排序
    final rawStrings = prefs.getStringList("heavy_stress_key") ?? [];
    final restoredList = rawStrings.map((e) => CatchLogItem.fromJson(e)).toList();
    restoredList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    // 清理
    await prefs.remove("heavy_stress_key");
    sw.stop();

    final bool heavySortOk = restoredList.length == 100 &&
        restoredList.first.id == "heavy_log_0" &&
        restoredList.last.id == "heavy_log_99";
    final int heavyLatencyMs = sw.elapsedMilliseconds;
    final bool heavyPerfOk = heavyLatencyMs < 200; // 100 筆讀寫必須在 200ms 內完成

    final bool test4Ok = heavySortOk && heavyPerfOk;
    print("║ • 04. 漁獲日誌 100 筆巨量壓測       : ${test4Ok ? '✅ 毫秒級通關' : '❌ 效能卡頓'} (${restoredList.length} 筆讀寫排序耗時: $heavyLatencyMs ms)");

    // ================= 5. 全台 85 站實體快照預報潮高物理區間深度審計 =================
    int validRangeCount = 0;
    final dir = Directory('deploy_api');
    final edgeFiles = dir.listSync().where((f) => f.path.contains('edge_') && f.path.endsWith('.json')).toList();

    for (var f in edgeFiles) {
      final file = File(f.path);
      final data = jsonDecode(await file.readAsString());
      final List forecasts = data['forecasts'] ?? [];
      bool stationOk = true;

      for (var fc in forecasts) {
        final double? h = double.tryParse(fc['TideHeights']?['AboveLocalMSL']?.toString() ?? '');
        // 台灣沿岸潮位歷史極值在 -300cm ~ +500cm 之間，絕不應出現 99999 異常噪訊
        if (h != null && (h < -300 || h > 500)) {
          stationOk = false;
          break;
        }
      }
      if (stationOk && forecasts.isNotEmpty) validRangeCount++;
    }

    final bool test5Ok = validRangeCount == 85;
    print("║ • 05. 85 站 30 天預報潮高物理合理性: ${test5Ok ? '✅ 100% 合理' : '❌ 數值離譜'} ($validRangeCount/85 站潮高數值均在 -300~500cm)");
    print("╚══════════════════════════════════════════════════════════════════════╝\n");

    expect(noDuplicateIds, isTrue, reason: "85 測站嚴禁有任何重複 ID 濫竽充數");
    expect(freeStationsAllPresent, isTrue, reason: "8 大免費口岸必須 100% 存在於 85 站名單中");
    expect(allCleaned, isTrue, reason: "風向、週期、流速等所有水文欄位遭遇 -99/-999 必須徹底清洗為 null");
    expect(nullSafetyOk, isTrue, reason: "全空 Observation 物件必須具備 100% 空安全");
    expect(test4Ok, isTrue, reason: "100 筆漁獲日誌存取排序必須在 200ms 內完成");
    expect(test5Ok, isTrue, reason: "85 站 30 天預報數值必須完全符合台灣沿岸海洋物理潮高範圍");
  });
}
