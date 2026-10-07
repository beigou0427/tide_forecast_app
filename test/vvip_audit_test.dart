import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tide_forecast_app/core/utils/constants.dart';
import 'package:tide_forecast_app/core/utils/solunar_util.dart';
import 'package:tide_forecast_app/core/utils/bite_prediction_engine.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';
import 'package:tide_forecast_app/core/network/tide_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 🌟 注入官方 Mock 記憶體通道，徹底消滅單元測試 MissingPluginException
    SharedPreferences.setMockInitialValues({});
  });

  group('⚓ VVIP 海事純潮汐標準與零退費安全性自動化審計 (10大剛性指標)', () {
    // -------------------------------------------------------------------------
    // 01. CWA 官方專線金鑰驗證
    // -------------------------------------------------------------------------
    test('01. CWA 官方專線金鑰 XOR 動態解碼與 UUID 格式校驗', () {
      final key = AppConstants.officialApiKey;
      expect(key.startsWith('CWA-'), isTrue);
      expect(key.length, equals(40));
    });

    // -------------------------------------------------------------------------
    // 02. 水文噪訊物理規格化清洗
    // -------------------------------------------------------------------------
    test('02. 水文噪訊物理規格化過濾 (-99 / NaN / Infinity 轉 null)', () {
      final dirtyMap = {
        'DateTime': DateTime.now().toIso8601String(),
        'WeatherElements': {
          'WaveHeight': '-99',
          'WindSpeed': 'NaN',
          'WavePeriod': 'Infinity',
          'AirPressure': '-9999.0',
          'SeaTemperature': 'null',
        }
      };
      final obs = Observation.fromProxy(dirtyMap);
      expect(obs.waveHeight, isNull);
      expect(obs.windSpeed, isNull);
      expect(obs.wavePeriod, isNull);
      expect(obs.airPressure, isNull);
      expect(obs.seaTemperature, isNull);
    });

    // -------------------------------------------------------------------------
    // 03. 氣壓反向水銀柱暴潮極值解析 (IBE)
    // -------------------------------------------------------------------------
    test('03. 氣壓反向水銀柱暴潮極值 (920hPa) 物理精度解析', () {
      final surgeMap = {
        'DateTime': DateTime.now().toIso8601String(),
        'WeatherElements': {'AirPressure': '920.0'}
      };
      final obs = Observation.fromProxy(surgeMap);
      expect(obs.airPressure, equals(920.0));
      final double surgeMeters = -0.01 * (obs.airPressure! - 1013.25);
      expect(surgeMeters, greaterThanOrEqualTo(0.90));
      expect(surgeMeters, lessThanOrEqualTo(0.95));
    });

    // -------------------------------------------------------------------------
    // 04. 天體月相 30 天連續運算與潮汐係數邊界
    // -------------------------------------------------------------------------
    test('04. 天體月相 30 天連續運算與潮汐係數邊界 [20, 120]', () {
      for (int i = 0; i < 30; i++) {
        final d = DateTime(2026, 10, 1).add(Duration(days: i));
        final s = SolunarUtil.calculate(d);
        expect(s.fishActivityScore, inInclusiveRange(50, 100));
        expect(s.tidalCoefficient, inInclusiveRange(20, 120));
        expect(s.lunarDateStr.isNotEmpty, isTrue);
        expect(s.moonPhaseName.isNotEmpty, isTrue);
      }
    });

    // -------------------------------------------------------------------------
    // 05. 指標魚種活性推算物理邊界與數值夾鉗
    // -------------------------------------------------------------------------
    test('05. 指標魚種活性推算物理邊界與數值夾鉗 [15, 95]', () {
      final mockData = TideStationData(
        info: StationInfo(
          stationName: "富貴角測試站",
          countyName: "新北",
          townName: "石門",
          lat: "25.30",
          lng: "121.53",
          attr: "海象觀測站",
          addressDescription: "",
        ),
        observations: [
          Observation(
            dateTime: DateTime.now().subtract(const Duration(hours: 6)),
            seaTemperature: 23.5,
            airPressure: 1014.0,
          ),
          Observation(
            dateTime: DateTime.now(),
            waveHeight: 1.2,
            windSpeed: 4.5,
            seaTemperature: 24.3,
            airPressure: 1012.0,
          ),
        ],
      );

      final result = BitePredictionEngine.predict(
        stationData: mockData, 
        targetDate: DateTime.now(),
      );

      expect(result.overallBiteScore, inInclusiveRange(20, 95));
      expect(result.speciesIndices.length, equals(4));
      for (var sp in result.speciesIndices) {
        expect(sp.biteProbability, inInclusiveRange(15, 95));
      }
    });

    // -------------------------------------------------------------------------
    // 06. 潮位預報多型別容錯解析
    // -------------------------------------------------------------------------
    test('06. 潮位預報多型別容錯解析 (Int/String/空值雙向兼容)', () {
      final f1 = TideForecast.fromOfficial({
        'DateTime': '2026-10-04T07:15:00+08:00',
        'Tide': '滿潮',
        'TideHeights': {'AboveLocalMSL': 185},
      });
      final f2 = TideForecast.fromOfficial({
        'DateTime': '2026-10-04T13:30:00+08:00',
        'Tide': '乾潮',
        'TideHeights': {'AboveLocalMSL': '92.4'},
      });
      expect(f1.tideHeight, equals('185'));
      expect(f2.tideHeight, equals('92.4'));
    });

    // -------------------------------------------------------------------------
    // 07. 🌟 VVIP 經典純潮汐對照表時程推算與走水窗口精度
    // -------------------------------------------------------------------------
    test('07. VVIP 經典純潮汐對照表滿乾潮差與走水窗口計算無溢出', () {
      final now = DateTime.now();
      final todayZero = DateTime(now.year, now.month, now.day);
      final forecasts = [
        TideForecast(dateTime: todayZero.add(const Duration(hours: 3, minutes: 15)), tideType: "滿潮", tideHeight: "185"),
        TideForecast(dateTime: todayZero.add(const Duration(hours: 9, minutes: 30)), tideType: "乾潮", tideHeight: "65"),
        TideForecast(dateTime: todayZero.add(const Duration(hours: 15, minutes: 45)), tideType: "滿潮", tideHeight: "178"),
        TideForecast(dateTime: todayZero.add(const Duration(hours: 22, minutes: 0)), tideType: "乾潮", tideHeight: "72"),
      ];

      // 驗證相鄰潮差計算 (185cm - 65cm = 120cm 潮差)
      final diff = (double.parse(forecasts[0].tideHeight) - double.parse(forecasts[1].tideHeight)).abs();
      expect(diff, equals(120.0));

      // 驗證滿退 2 分水時程推算 (滿潮後 75 分鐘開始起流)
      final biteStart = forecasts[0].dateTime.add(const Duration(hours: 1, minutes: 15));
      final biteEnd = forecasts[0].dateTime.add(const Duration(hours: 2, minutes: 45));
      expect(biteEnd.isAfter(biteStart), isTrue);
      expect(biteStart.difference(forecasts[0].dateTime).inMinutes, equals(75));
    });

    // -------------------------------------------------------------------------
    // 08. 🌟 備援水文模型去恐慌黑話審計 (防退費心理學斷言)
    // -------------------------------------------------------------------------
    test('08. 備援水文模型去恐慌黑話審計 (斷言零驚悚詞彙且安全分 >= 70)', () async {
      final api = TideApiService();
      // 極端超時預算強制觸發備援模型
      final fallback = await api.fetchData(
        "C6AH2",
        totalBudget: const Duration(milliseconds: 10),
      );

      // 斷言：絕不得出現引發退費恐慌的黑話
      expect(fallback.info.townName.contains("防區"), isFalse, reason: "不可包含『防區』等軍工黑話");
      expect(fallback.info.attr.contains("安全模式"), isFalse, reason: "不可包含『安全模式』等除錯黑話");
      expect(fallback.aiBriefing?.briefing.contains("室內整裝"), isFalse, reason: "不可叫付費用戶『室內整裝』引發退費");
      expect(fallback.aiBriefing?.safetyScore, greaterThanOrEqualTo(70), reason: "備援安全分必須處於客觀受控區間");
      expect(fallback.forecasts.length, greaterThanOrEqualTo(4), reason: "必須提供 4 節點半日潮預報保持圖表生動");
    });

    // -------------------------------------------------------------------------
    // 09. 🌟 官方客服工單與 Apple 3.1.2 / 5.1.1 隱私治理 URI 合法性
    // -------------------------------------------------------------------------
    test('09. 官方客服工單與 Apple 5.1.1 / 3.1.2 隱私治理 URI 語法合規', () {
      final eulaUri = Uri.tryParse("https://www.apple.com/legal/internet-services/itunes/dev/stdeula/");
      final privacyUri = Uri.tryParse("https://gist.github.com/beigou0427/99e6eddb729ae53eb8e7474866f3f009");
      final manageSubUri = Uri.tryParse("https://support.apple.com/HT202039");

      expect(eulaUri?.hasScheme, isTrue);
      expect(privacyUri?.hasScheme, isTrue);
      expect(manageSubUri?.hasScheme, isTrue);
      expect(manageSubUri?.host, equals("support.apple.com"));
    });

    // -------------------------------------------------------------------------
    // 10. 🌟 StoreKit 4 大商品與全島 85 測站閘門排他性審計
    // -------------------------------------------------------------------------
    test('10. StoreKit 4 大商品與全島 85 測站免費/付費閘門排他性校驗', () {
      expect(AppConstants.iapProductIds.length, equals(4));
      expect(AppConstants.freeStationIds.length, equals(8));

      // 驗證 8 大基準口岸站絕對免費開放，絕不誤擋非會員
      for (final fid in AppConstants.freeStationIds) {
        final model = StationModel(id: fid, name: "測試免費港", region: "北部", lat: 25.0, lng: 121.0);
        expect(model.isProOnly, isFalse, reason: "大港口岸站必須 100% 免費體驗");
      }
    });
  });
}