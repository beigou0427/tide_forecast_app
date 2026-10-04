import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/core/utils/constants.dart';
import 'package:tide_forecast_app/core/utils/solunar_util.dart';
import 'package:tide_forecast_app/core/utils/bite_prediction_engine.dart';
import 'package:tide_forecast_app/features/tide/data/tide_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('⚓ VVIP 海事純潮汐標準與安全性自動化審計', () {
    test('01. CWA 官方專線金鑰 XOR 動態解碼與 UUID 格式校驗', () {
      final key = AppConstants.officialApiKey;
      expect(key.startsWith('CWA-'), isTrue);
      expect(key.length, equals(40));
    });

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

    test('05. 指標魚種活性推算物理邊界與數值夾鉗 [15, 95]', () {
      final mockData = TideStationData(
        info: StationInfo(
          stationName: "富貴角測試站",
          countyName: "新北",
          townName: "石門",
          lat: "25.30",
          lng: "121.53",
          attr: "資料浮標",
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
  });
}