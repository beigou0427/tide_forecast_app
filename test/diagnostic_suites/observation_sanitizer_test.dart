import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/observation_sanitizer_suite.dart';

void main() {
  group('🔍 【功能 04 專項自檢】James Bach 探索性特異點破壞與水文邊界審計', () {
    
    test('【基底測試】官方自檢套件標準髒數據清洗與空值容錯', () async {
      final result = await ObservationSanitizerDiagnosticSuite.run();

      print("\n╔══════════════════════════════════════════════════════════════╗");
      print("║   🔍 【功能 04 專項自檢：水文觀測髒數據清洗與型態安全】        ║");
      print("╠══════════════════════════════════════════════════════════════╣");
      print("║ • 雜訊清洗 : ${result.isDirtyStringCleaned ? '✅ 成功' : '❌ 失敗'} (-99 / None / nan / null 安全轉為 null)");
      print("║ • 數值提取 : ${result.isExtremeNoiseFiltered ? '✅ 正常' : '❌ 異常'} (高低極限浮點數提取無例外)");
      print("║ • 精度保留 : ${result.isNormalPrecisionRetained ? '✅ 無損' : '❌ 失真'} (正常水溫/氣壓/潮高數值零精度丟失)");
      print("║ • 空值防禦 : ${result.isEmptyJsonCrashProof ? '✅ 零崩潰' : '❌ 崩潰'} (全空畸形 JSON 注入零閃退)");
      print("║ • 審計結論 : ${result.message}");
      print("╚══════════════════════════════════════════════════════════════╝\n");

      expect(result.isDirtyStringCleaned, isTrue, reason: "髒數據必須安全清洗為 null，絕不拋 FormatException");
      expect(result.isExtremeNoiseFiltered, isTrue, reason: "數值提取邏輯必須健全");
      expect(result.isNormalPrecisionRetained, isTrue, reason: "正常數值必須 100% 保留小數點精確度");
      expect(result.isEmptyJsonCrashProof, isTrue, reason: "全空 JSON 物件嚴禁拋出未捕獲崩潰");
    });

    // 🌟 James Bach 特異點 1：浮標加速度計 0.0m 卡死故障識別
    test('James Bach 特異點 01: 開闊海域 0.0m 波高必須識別為感測器卡死並清洗為 null', () {
      final stasisMap = {
        'DateTime': '2026-09-23T14:30:00+08:00',
        'WeatherElements': {'WaveHeight': '0.00'} // 物理不可能之 0.0m
      };
      final obs = Observation.fromProxy(stasisMap);
      expect(obs.waveHeight, isNull, reason: "0.0m 波高被誤判為平靜無波，應為加速度計卡死！");
    });

    // 🌟 James Bach 特異點 2：大潮乾潮底合法負水深豁免 (-45cm)
    test('James Bach 特異點 02: 澎湖/金門大潮乾潮底合法負水深 (-45cm) 嚴禁被誤殺', () {
      final negativeTideMap = {
        'DateTime': '2026-09-23T14:30:00+08:00',
        'WeatherElements': {'TideHeight': '-45.0'} // 金門合法大潮負水深 (cm)
      };
      final obs = Observation.fromProxy(negativeTideMap);
      expect(obs.tideHeight, equals(-45.0), reason: "大潮乾潮底合法負水深遭到清洗誤殺！");
    });

    // 🌟 James Bach 特異點 3：大氣極限氣壓穿透阻斷 (500hPa 破綻值)
    test('James Bach 特異點 03: 500hPa 非地球海平面極限氣壓必須被阻斷為 null', () {
      final badPressureMap = {
        'DateTime': '2026-09-23T14:30:00+08:00',
        'WeatherElements': {'AirPressure': '500.0'} // 地球海平面不可能存在之 500hPa
      };
      final obs = Observation.fromProxy(badPressureMap);
      expect(obs.airPressure, isNull, reason: "500hPa 破綻氣壓未被物理規格化邊界阻斷！");
    });

    // 🌟 James Bach 特異點 4：電磁噪訊 720° 風向阻斷
    test('James Bach 特異點 04: 720° 電磁脈衝干擾風向必須阻斷為 null', () {
      final badWindDirMap = {
        'DateTime': '2026-09-23T14:30:00+08:00',
        'WeatherElements': {'WindDirection': '720.0'} // 超越 360 度之異常噪訊
      };
      final obs = Observation.fromProxy(badWindDirMap);
      expect(obs.windDirection, isNull, reason: "720° 超限風向未被阻斷！");
    });
  });
}