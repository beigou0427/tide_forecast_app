import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/full_stations_audit_suite.dart';

void main() {
  test('【全量穿透審計】硬碟 85 測站實體 JSON 檔案逐一開檔無死角大普查', () async {
    final result = await FullStationsAuditSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║  🔬 【85 測站實體 JSON 檔案全量深層普查報告 (零 Mock)】     ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 實體檔案總數 : ${result.totalAudited == 85 ? '✅ 完整' : '❌ 缺失'} (${result.totalAudited}/85 個 edge_*.json)");
    print("║ • 預報陣列在庫 : ${result.missingForecasts == 0 ? '✅ 達標' : '❌ 短缺'} (異常數: ${result.missingForecasts} 站)");
    print("║ • 中文地名轉譯 : ${result.untranslatedNames == 0 ? '✅ 100% 轉譯' : '❌ 存在純代碼'} (未轉譯: ${result.untranslatedNames} 站)");
    print("║ • 安全評分區間 : ${result.invalidScores == 0 ? '✅ 正常' : '❌ 溢出'} (異常分: ${result.invalidScores} 站)");
    print("║ • 坐標區域對齊 : ${result.coordinateErrors == 0 ? '✅ 精準' : '❌ 坐標錯位'} (錯位數: ${result.coordinateErrors} 站)");
    print("║ • 完好合格站數 : ${result.validStations == 85 ? '✅ 85/85 全數合格' : '❌ 僅 ${result.validStations}/85 合格'}");
    print("║ • 審查缺陷清單 : ${result.errorStationIds.isEmpty ? '無任何缺陷 (Zero Defects)' : result.errorStationIds}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.totalAudited, 85, reason: "硬碟內 edge_*.json 必須剛好為 85 份實體檔案");
    expect(result.validStations, 85, reason: "全台 85 個測站檔案必須 100% 全部通過預報、地名與坐標實測");
    expect(result.errorStationIds, isEmpty, reason: "嚴禁有任何測站存在缺陷：${result.errorStationIds}");
  });
}
