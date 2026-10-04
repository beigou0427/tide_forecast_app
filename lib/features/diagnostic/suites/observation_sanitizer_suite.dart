import 'package:tide_forecast_app/features/tide/data/tide_model.dart';

class ObservationSanitizerSuiteResult {
  final bool isDirtyStringCleaned;
  final bool isExtremeNoiseFiltered;
  final bool isNormalPrecisionRetained;
  final bool isEmptyJsonCrashProof;
  final String message;

  const ObservationSanitizerSuiteResult({
    required this.isDirtyStringCleaned,
    required this.isExtremeNoiseFiltered,
    required this.isNormalPrecisionRetained,
    required this.isEmptyJsonCrashProof,
    required this.message,
  });

  bool get isAllPassed =>
      isDirtyStringCleaned &&
      isExtremeNoiseFiltered &&
      isNormalPrecisionRetained &&
      isEmptyJsonCrashProof;
}

/// 🌟 對齊 Philip Crosby 零缺陷規格化之水文清洗診斷套件
class ObservationSanitizerDiagnosticSuite {
  static Future<ObservationSanitizerSuiteResult> run() async {
    // 1. 測試極端髒字串清洗為 null (絕不拋 FormatException)
    bool dirtyOk = false;
    try {
      final dirtyMap = {
        'DateTime': DateTime.now().toIso8601String(),
        'WeatherElements': {
          'TideHeight': 'None',
          'WaveHeight': '-99',
          'WindSpeed': 'nan',
          'SeaTemperature': 'null',
          'AirTemperature': '',
          'AirPressure': ' -999 '
        }
      };
      final obs = Observation.fromProxy(dirtyMap);
      dirtyOk = obs.tideHeight == null &&
          obs.waveHeight == null &&
          obs.windSpeed == null &&
          obs.seaTemperature == null &&
          obs.airTemperature == null &&
          obs.airPressure == null;
    } catch (_) {
      dirtyOk = false;
    }

    // 2. 🌟 測試物理極限值過濾 (浪高 > 25m、風速 > 75m/s 的感測器硬體破綻噪訊必須安全過濾為 null)
    bool noiseFilterOk = false;
    try {
      final noiseMap = {
        'DateTime': DateTime.now().toIso8601String(),
        'WeatherElements': {
          'WaveHeight': '99.9',  // 超限異常浪高噪訊 (應過濾為 null)
          'WindSpeed': '120.0',  // 超限異常風速噪訊 (應過濾為 null)
        }
      };
      final obs = Observation.fromProxy(noiseMap);
      // 驗證硬體超限噪訊已被物理規格化邊界安全攔截為 null
      noiseFilterOk = (obs.waveHeight == null && obs.windSpeed == null);
    } catch (_) {
      noiseFilterOk = false;
    }

    // 3. 測試正常高精度水文數值無損保留
    bool precisionOk = false;
    try {
      final normalMap = {
        'DateTime': '2026-09-23T14:30:00+08:00',
        'WeatherElements': {
          'TideHeight': '1.85',
          'WaveHeight': '1.24',
          'WindSpeed': '6.7',
          'SeaTemperature': '25.6',
          'AirTemperature': '28.3',
          'AirPressure': '1012.4'
        }
      };
      final obs = Observation.fromProxy(normalMap);
      precisionOk = obs.tideHeight == 1.85 &&
          obs.waveHeight == 1.24 &&
          obs.windSpeed == 6.7 &&
          obs.seaTemperature == 25.6 &&
          obs.airTemperature == 28.3 &&
          obs.airPressure == 1012.4;
    } catch (_) {
      precisionOk = false;
    }

    // 4. 測試全空畸形 JSON 結構零崩潰注入
    bool emptyCrashProof = false;
    try {
      final emptyObs = Observation.fromProxy({});
      emptyCrashProof = emptyObs.dateTime != null && emptyObs.waveHeight == null;
    } catch (_) {
      emptyCrashProof = false;
    }

    String msg;
    if (!dirtyOk) {
      msg = "髒字串 (-99/None/nan) 清洗失敗，未能安全轉為 null";
    } else if (!noiseFilterOk) {
      msg = "超限物理噪訊 (99.9m浪高/120m/s風速) 未被安全過濾為 null";
    } else if (!precisionOk) {
      msg = "正常水文數據精度解析失真";
    } else if (!emptyCrashProof) {
      msg = "空 JSON 結構注入時拋出未捕獲崩潰";
    } else {
      msg = "水文髒數據清洗防護完好，超限噪訊完全攔截，正常精度無損";
    }

    return ObservationSanitizerSuiteResult(
      isDirtyStringCleaned: dirtyOk,
      isExtremeNoiseFiltered: noiseFilterOk,
      isNormalPrecisionRetained: precisionOk,
      isEmptyJsonCrashProof: emptyCrashProof,
      message: msg,
    );
  }
}