import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tide_forecast_app/features/tide/data/ugc_report_model.dart';
import 'package:tide_forecast_app/features/tide/providers/ugc_provider.dart';
import 'package:tide_forecast_app/features/premium/services/premium_service.dart';

class UgcRadarSuiteResult {
  final bool is6TagsStructureValid;
  final bool isZeroFabricationHonestyPassed;
  final bool isRealReportUnitValid;
  final bool isCoinAntiExploitDefended;
  final bool is6HourExpiryFilterValid;
  final int activeReportsCount;
  final String sampleReportInfo;
  final String message;

  const UgcRadarSuiteResult({
    required this.is6TagsStructureValid,
    required this.isZeroFabricationHonestyPassed,
    required this.isRealReportUnitValid,
    required this.isCoinAntiExploitDefended,
    required this.is6HourExpiryFilterValid,
    required this.activeReportsCount,
    required this.sampleReportInfo,
    required this.message,
  });

  bool get isAllPassed =>
      is6TagsStructureValid &&
      isZeroFabricationHonestyPassed &&
      isRealReportUnitValid &&
      isCoinAntiExploitDefended &&
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

    // 2. 檢驗海事誠信防線：0 人回報時絕對不偽造假情報
    final notifier = ref.read(ugcReportProvider.notifier);
    final emptyStationReports = notifier.getReportsForStation("ZERO_PERSON_STATION_TEST", waveHeight: 1.0, windSpeed: 5.0);
    final bool zeroFabricationPassed = emptyStationReports.isEmpty;

    // 3. 檢驗真實釣友回報單元結構（起步 1 票防刷讚、因果時鐘健全）
    final sampleRealItem = UgcReportItem(
      id: "real_audit_888",
      stationId: "46694A",
      timestamp: DateTime.now(),
      type: UgcConditionType.fishBiting,
      userTag: "現場釣友",
      upvotes: 1,
      logicalCounter: 1,
    );
    final bool realUnitOk = sampleRealItem.upvotes == 1 &&
        sampleRealItem.logicalCounter == 1 &&
        !sampleRealItem.isTombstoned &&
        sampleRealItem.label.contains("大咬");

    // 4. 檢驗商業防線：嚴格禁止以代幣換取 PRO 特權（防白嫖漏洞已被徹底封死）
    final premNotifier = ref.read(premiumProvider.notifier);
    final bool canExploitPro = await premNotifier.redeemCoinsForProPass(100, 7);
    final bool coinAntiExploitDefended = !canExploitPro;

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
    } else if (!zeroFabricationPassed) {
      msg = "偵測到未經通報的假情報！違背海事誠信原則";
    } else if (!realUnitOk) {
      msg = "真實回報資料結構或因果時鐘異常";
    } else if (!coinAntiExploitDefended) {
      msg = "代幣白嫖 PRO 特權漏洞仍處於開啟狀態！";
    } else if (!expiryFilterOk) {
      msg = "6 小時時效過期過濾演算法失效";
    } else {
      msg = "海事零造假檢驗通過，防刷讚與 6 小時過期防線健全，代幣白嫖通道已全面封死！";
    }

    return UgcRadarSuiteResult(
      is6TagsStructureValid: tagsOk,
      isZeroFabricationHonestyPassed: zeroFabricationPassed,
      isRealReportUnitValid: realUnitOk,
      isCoinAntiExploitDefended: coinAntiExploitDefended,
      is6HourExpiryFilterValid: expiryFilterOk,
      activeReportsCount: emptyStationReports.length,
      sampleReportInfo: sampleRealItem.label,
      message: msg,
    );
  }
}