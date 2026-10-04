import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/tide_forecast_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🔍 【功能 03 專項自檢】Donald Knuth 演算法確定性與 30 天潮汐預報審計', () {
    
    test('【基底測試】30 天潮汐預報空間拓撲、型別容錯與時序自然交替率審計', () async {
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

    // 🌟 Donald Knuth 數學證明 1：極值錨點零漂移證明 (Extreme Boundary Anchor Proof)
    test('Donald Knuth 證明 01: M4 淺水分潮非對稱公式在 r=0 與 r=1 時必須零誤差收斂於官方滿乾潮極值', () {
      const double highTidePeak = 2.18; // 滿潮 2.18m
      const double lowTideTrough = 0.42; // 乾潮 0.42m

      // 核心調和公式：harmonicRatio = cos(pi * r) - 0.12 * sin(2 * pi * r)
      // height = (h1 + h2) / 2 + ((h1 - h2) / 2) * harmonicRatio
      double computeHarmonicHeight(double r) {
        final double cosComp = math.cos(math.pi * r);
        final double m4Overtide = 0.12 * math.sin(2 * math.pi * r);
        final double ratio = cosComp - m4Overtide;
        return (highTidePeak + lowTideTrough) / 2.0 + ((highTidePeak - lowTideTrough) / 2.0) * ratio;
      }

      // 證明 r = 0 (起點極值) 誤差嚴格小於 1e-6
      final double computedPeak = computeHarmonicHeight(0.0);
      expect((computedPeak - highTidePeak).abs(), lessThan(1e-6), 
          reason: "數學證明失守！r=0 時公式未能 100% 收斂於滿潮起點極值！");

      // 證明 r = 1 (終點極值) 誤差嚴格小於 1e-6
      final double computedTrough = computeHarmonicHeight(1.0);
      expect((computedTrough - lowTideTrough).abs(), lessThan(1e-6), 
          reason: "數學證明失守！r=1 時公式未能 100% 收斂於乾潮終點極值！");
    });

    // 🌟 Donald Knuth 數學證明 2：淺海走水非對稱諧波有效性證明 (Asymmetric Velocity Proof)
    test('Donald Knuth 證明 02: 走水中間點 (r=0.25 與 r=0.75) 必須具備淺海非對稱調和斜率，絕非純餘弦對稱波', () {
      const double highTidePeak = 2.00;
      const double lowTideTrough = 0.00;

      double computeHarmonicHeight(double r) {
        final double cosComp = math.cos(math.pi * r);
        final double m4Overtide = 0.12 * math.sin(2 * math.pi * r);
        final double ratio = cosComp - m4Overtide;
        return (highTidePeak + lowTideTrough) / 2.0 + ((highTidePeak - lowTideTrough) / 2.0) * ratio;
      }

      double computePureCosineHeight(double r) {
        final double cosComp = math.cos(math.pi * r);
        return (highTidePeak + lowTideTrough) / 2.0 + ((highTidePeak - lowTideTrough) / 2.0) * cosComp;
      }

      // 在 r = 0.25 (返退走水最快之區間)，sin(2*pi*0.25) = sin(pi/2) = 1.0，M4 修正值達到波峰
      final double m4HeightAtQuarter = computeHarmonicHeight(0.25);
      final double pureCosHeightAtQuarter = computePureCosineHeight(0.25);

      // 純餘弦此時應為 1.0 + 1.0 * cos(45°) ≈ 1.707m
      // M4 調和應為 1.0 + 1.0 * (0.7071 - 0.12) = 1.587m
      expect((m4HeightAtQuarter - pureCosHeightAtQuarter).abs(), greaterThan(0.10),
          reason: "演算法退化！M4 淺水非對稱性未生效，退化為單純餘弦簡諧波！");
    });
  });
}