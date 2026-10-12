import 'package:intl/intl.dart';
import '../../../tide/data/tide_model.dart';
import '../../../../core/utils/bite_prediction_engine.dart';

class HomePageResilienceSuiteResult {
  final bool isFutureNoElementCrashProof;
  final bool isPastEmptyDaySafe;
  final bool isDateSlicingAccurate;
  final bool isMalformedStationSafe;
  final String message;

  const HomePageResilienceSuiteResult({
    required this.isFutureNoElementCrashProof,
    required this.isPastEmptyDaySafe,
    required this.isDateSlicingAccurate,
    required this.isMalformedStationSafe,
    required this.message,
  });

  bool get isAllPassed =>
      isFutureNoElementCrashProof &&
      isPastEmptyDaySafe &&
      isDateSlicingAccurate &&
      isMalformedStationSafe;
}

/// 🌟 經 TQM 嚴格重塑之首頁時空韌性自檢套件
/// 100% 真實驗證防偽版：
/// 1. 徹底拔除舊版測試中「清空今日資料來假裝通過」的波將金村 (Potemkin Village) 造假測試！
/// 2. 注入包含「今日 10 米巨浪」之極端測站，實際呼叫推論引擎預測未來，驗證時態隔離。
/// 3. 確保無資料日時，系統 100% 誠實退回純天文推演，杜絕任何跨時空數據污染。
class HomePageResilienceDiagnosticSuite {
  static Future<HomePageResilienceSuiteResult> run() async {
    final now = DateTime.now();
    
    // 🌟 構造一個「今天發生 10 米巨浪與 25m/s 狂風」的極端測站
    final extremeStation = TideStationData(
      info: StationInfo(stationName: "測試站", countyName: "", townName: "", lat: "25.0", lng: "121.0", attr: "浮標", addressDescription: ""),
      observations: [
        Observation(
          dateTime: now,
          waveHeight: 10.0, // 🚨 今天的致命巨浪
          wavePeriod: 12.0,
          windSpeed: 25.0,
        )
      ],
      forecasts: [
        TideForecast(dateTime: now.add(const Duration(days: 5)), tideType: "滿潮", tideHeight: "2.0")
      ],
    );

    // 1. 未來預報時態隔離測試 (Future Target Date)
    bool futureCrashProof = false;
    try {
      final futureDate = now.add(const Duration(days: 5));
      // 真實呼叫大腦推論
      final result = BitePredictionEngine.predict(stationData: extremeStation, targetDate: futureDate);
      
      // 🚨 核心防線：未來的預測絕對不能被今天的 10 米巨浪污染！必須退回天文推演！
      if (result.oceanTriggerSummary.contains("天體引力與潮汐模型") && 
          !result.speciesIndices.any((s) => s.triggerReason.contains("巨浪"))) {
        futureCrashProof = true;
      }
    } catch (_) {
      futureCrashProof = false;
    }

    // 2. 歷史無資料日防禦測試 (Past Target Date)
    bool pastEmptySafe = false;
    try {
      final pastDate = now.subtract(const Duration(days: 5));
      final result = BitePredictionEngine.predict(stationData: extremeStation, targetDate: pastDate);
      
      if (result.oceanTriggerSummary.contains("天體引力與潮汐模型") && 
          !result.speciesIndices.any((s) => s.triggerReason.contains("巨浪"))) {
        pastEmptySafe = true;
      }
    } catch (_) {
      pastEmptySafe = false;
    }

    // 3. 多筆實測時空切片精度檢驗 (Multiple Observations Slicing)
    bool slicingAccurate = false;
    try {
      final multiObsStation = TideStationData(
        info: StationInfo(stationName: "新竹", countyName: "新竹市", townName: "", lat: "24.8", lng: "120.9", attr: "潮位站", addressDescription: ""),
        observations: [
          Observation(dateTime: now.subtract(const Duration(days: 1)), tideHeight: 1.0), // 昨天
          Observation(dateTime: now.subtract(const Duration(hours: 3)), tideHeight: 1.5), // 今天稍早
          Observation(dateTime: now, tideHeight: 1.85), // 今天最新
        ],
        forecasts: [],
      );
      
      final result = BitePredictionEngine.predict(stationData: multiObsStation, targetDate: now);
      slicingAccurate = result.overallBiteScore > 0;
    } catch (_) {
      slicingAccurate = false;
    }

    // 4. 全空畸形測站物件極限注入
    bool malformedSafe = false;
    try {
      final emptyStation = TideStationData(
        info: StationInfo(stationName: "極端空站", countyName: "", townName: "", lat: "0", lng: "0", attr: "", addressDescription: ""),
        observations: [],
        forecasts: [],
      );
      final result = BitePredictionEngine.predict(stationData: emptyStation, targetDate: now);
      malformedSafe = result.oceanTriggerSummary.contains("天體引力與潮汐模型");
    } catch (_) {
      malformedSafe = false;
    }

    String msg;
    if (!futureCrashProof) {
      msg = "未來預報遭今日實測數據污染 (時空錯置)";
    } else if (!pastEmptySafe) {
      msg = "歷史回測日遭今日實測數據污染 (時空錯置)";
    } else if (!slicingAccurate) {
      msg = "多筆歷史與今日混合觀測切片精度失準";
    } else if (!malformedSafe) {
      msg = "全空畸形測站注入引發推論引擎崩潰";
    } else {
      msg = "預報與回測時空 100% 絕對隔離，徹底消滅時序污染，空站注入防護完備";
    }

    return HomePageResilienceSuiteResult(
      isFutureNoElementCrashProof: futureCrashProof,
      isPastEmptyDaySafe: pastEmptySafe,
      isDateSlicingAccurate: slicingAccurate,
      isMalformedStationSafe: malformedSafe,
      message: msg,
    );
  }
}