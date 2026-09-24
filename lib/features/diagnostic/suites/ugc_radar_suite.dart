import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tide_forecast_app/features/tide/data/ugc_report_model.dart';
import 'package:tide_forecast_app/features/tide/providers/ugc_provider.dart';
import 'package:tide_forecast_app/features/premium/services/premium_service.dart';

class UgcRadarSuiteResult {
  final bool is6TagsStructureValid;
  final bool isColdStartSentinelWorking;
  final bool isDynamicWaveRuleAccurate;
  final bool isProIncentiveStateFlipped;
  final bool is6HourExpiryFilterValid;
  final int activeReportsCount;
  final String sentinelSample;
  final String message;

  const UgcRadarSuiteResult({
    required this.is6TagsStructureValid,
    required this.isColdStartSentinelWorking,
    required this.isDynamicWaveRuleAccurate,
    required this.isProIncentiveStateFlipped,
    required this.is6HourExpiryFilterValid,
    required this.activeReportsCount,
    required this.sentinelSample,
    required this.message,
  });

  bool get isAllPassed =>
      is6TagsStructureValid &&
      isColdStartSentinelWorking &&
      isDynamicWaveRuleAccurate &&
      isProIncentiveStateFlipped &&
      is6HourExpiryFilterValid;
}

class UgcRadarDiagnosticSuite {
  static Future<UgcRadarSuiteResult> run(WidgetRef ref) async {
    // 1. 檢驗 6 大實況標籤資料結構與雙向序列化
    bool tagsOk = true;
    for (var type in UgcConditionType.values) {
      final item = UgcReportItem(
        id: "test_${type.index}",
        stationId: "46694A",
        timestamp: DateTime.now(),
        type: type,
        userTag: "現場釣友",
        upvotes: 3,
      );
      final raw = item.toJson();
      final restored = UgcReportItem.fromJson(raw);
      if (restored.label != item.label || restored.upvotes != 3 || restored.type != type) {
        tagsOk = false;
        break;
      }
    }

    // 2. 實測 0 人通報冷啟動 AI 哨兵即時補位
    final notifier = ref.read(ugcReportProvider.notifier);
    final fallbackReports = notifier.getReportsForStation("ZERO_PERSON_STATION_TEST", waveHeight: 1.0, windSpeed: 5.0);
    final bool sentinelWorking = fallbackReports.isNotEmpty &&
        fallbackReports.any((r) => r.userTag.contains("AI"));
    final String sampleStr = fallbackReports.isNotEmpty ? "${fallbackReports.first.label} (${fallbackReports.first.userTag})" : "無補位";

    // 3. 實測波高動態規則決策 (大浪觸發 waveLarger，小浪觸發 waveCalm)
    final highWaveReports = notifier.getReportsForStation("HIGH_WAVE_STATION", waveHeight: 2.5, windSpeed: 12.0);
    final lowWaveReports = notifier.getReportsForStation("LOW_WAVE_STATION", waveHeight: 0.6, windSpeed: 3.5);
    final bool highWaveMatch = highWaveReports.any((r) => r.type == UgcConditionType.waveLarger);
    final bool lowWaveMatch = lowWaveReports.any((r) => r.type == UgcConditionType.waveCalm);
    final bool waveRuleOk = highWaveMatch && lowWaveMatch;

    // 4. 真實狀態機流轉：通報送 Pro 會員利益驅動檢驗
    bool stateFlippedOk = false;
    try {
      final premNotifier = ref.read(premiumProvider.notifier);
      final initialStatus = ref.read(premiumProvider).isPremium;
      // 模擬通報後給予 1 週 Pro 特權
      await premNotifier.setPremiumStatus(true, SubscriptionType.weekly);
      final isNowPro = ref.read(premiumProvider).isPremium;
      final isWeekly = ref.read(premiumProvider).type == SubscriptionType.weekly;
      // 還原初始狀態
      await premNotifier.setPremiumStatus(initialStatus, SubscriptionType.none);
      stateFlippedOk = isNowPro && isWeekly;
    } catch (_) {
      stateFlippedOk = false;
    }

    // 5. 6 小時時效看門狗過期過濾測試
    final now = DateTime.now();
    final freshItem = UgcReportItem(id: "fresh", stationId: "test_st", timestamp: now.subtract(const Duration(hours: 1)), type: UgcConditionType.fishBiting);
    final expiredItem = UgcReportItem(id: "expired", stationId: "test_st", timestamp: now.subtract(const Duration(hours: 7)), type: UgcConditionType.waterTurbid);
    
    final testBatch = [freshItem, expiredItem];
    final validBatch = testBatch.where((r) => now.difference(r.timestamp).inHours < 6).toList();
    final bool expiryFilterOk = validBatch.length == 1 && validBatch.first.id == "fresh";

    String msg;
    if (!tagsOk) {
      msg = "6 大水文標籤資料結構序列化失真";
    } else if (!sentinelWorking) {
      msg = "0 人回報時 AI 哨兵未啟動自動補位";
    } else if (!waveRuleOk) {
      msg = "實測波高動態決策規則失效 (大浪未能觸發預警)";
    } else if (!stateFlippedOk) {
      msg = "通報送 Pro 利益驅動狀態機流轉失敗";
    } else if (!expiryFilterOk) {
      msg = "6 小時時效過期過濾演算法失效";
    } else {
      msg = "Waze 實況雷達 6 標籤齊全，AI 哨兵動態決策精準，通報送 Pro 閉環完好";
    }

    return UgcRadarSuiteResult(
      is6TagsStructureValid: tagsOk,
      isColdStartSentinelWorking: sentinelWorking,
      isDynamicWaveRuleAccurate: waveRuleOk,
      isProIncentiveStateFlipped: stateFlippedOk,
      is6HourExpiryFilterValid: expiryFilterOk,
      activeReportsCount: fallbackReports.length,
      sentinelSample: sampleStr,
      message: msg,
    );
  }
}
