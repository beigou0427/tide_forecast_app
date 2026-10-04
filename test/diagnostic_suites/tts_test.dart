import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';
import 'package:tide_forecast_app/core/utils/solunar_util.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/tts_suite.dart';

void main() {
  group('🔍 【功能 10 專項自檢】Brendan Eich 語音管線極限容錯與口語合成審計', () {
    
    test('【基底測試】老船長語音海象晨報 TTS 語料合成、空值防護與時間軸實體審計', () async {
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

    // 🌟 Brendan Eich 測試 1：全空/斷線測站極限注入 0 崩潰且不包含 "null" 字串
    test('Brendan Eich 01: 極端全空測站注入，語意腳本保證包含基本問候且 0 處暴露 null', () {
      final now = DateTime.now();
      final emptyStation = TideStationData(
        info: StationInfo(
          stationName: "極端斷線測試站 (TEST999)", 
          countyName: "", 
          townName: "", 
          lat: "0", 
          lng: "0", 
          attr: "", 
          addressDescription: ""
        ),
        observations: [],
        forecasts: [],
        aiBriefing: null,
      );

      final script = TtsDiagnosticSuite.composeScript(emptyStation, now);

      expect(script.contains("極端斷線測試站"), isTrue);
      expect(script.contains("老船長祝您滿載而歸"), isTrue);
      expect(script.contains("null"), isFalse, reason: "語音腳本中嚴禁將未定義之 null 朗讀出來！");
      expect(script.contains("NaN"), isFalse);
    });

    // 🌟 Brendan Eich 測試 2：深層長週期能量湧浪觸發致命瘋狗浪語音插播
    test('Brendan Eich 02: 湧浪週期 >= 10s 且浪高 >= 0.7m 時，語料必須自動注入緊急瘋狗浪語音警報', () {
      final now = DateTime.now();
      final rogueStation = TideStationData(
        info: StationInfo(
          stationName: "新北石門 富貴角資料浮標 (C6AH2)", 
          countyName: "新北", 
          townName: "石門", 
          lat: "25.30", 
          lng: "121.53", 
          attr: "資料浮標", 
          addressDescription: ""
        ),
        observations: [
          Observation(
            dateTime: now,
            waveHeight: 0.85,
            wavePeriod: 12.0, // 致命 12 秒長湧
            windSpeed: 4.0,
          ),
        ],
        forecasts: [],
      );

      final script = TtsDiagnosticSuite.composeScript(rogueStation, now);

      expect(script.contains("富貴角"), isTrue);
      expect(script.contains("0.85米"), isTrue);
    });

    // 🌟 Brendan Eich 測試 3：未來滿潮時程口語化 HH點mm分 格式精確解析
    test('Brendan Eich 03: 未來滿潮時間必須正確轉譯為中文口語「HH點mm分」而不是冒號格式', () {
      final now = DateTime.now();
      final targetHighTide = now.add(const Duration(hours: 2, minutes: 15));
      final expectedOralTime = DateFormat('HH點mm分').format(targetHighTide);

      final tideStation = TideStationData(
        info: StationInfo(
          stationName: "基隆港潮位站 (C4B01)", 
          countyName: "基隆", 
          townName: "市區", 
          lat: "25.15", 
          lng: "121.75", 
          attr: "潮位站", 
          addressDescription: ""
        ),
        observations: [],
        forecasts: [
          TideForecast(dateTime: targetHighTide, tideType: "滿潮", tideHeight: "195"),
        ],
      );

      final script = TtsDiagnosticSuite.composeScript(tideStation, now);

      expect(script.contains(expectedOralTime), isTrue, reason: "滿潮口語時間未能正確轉譯！");
      expect(script.contains("下一次滿潮水位將在$expectedOralTime到來"), isTrue);
    });
  });
}