import 'package:flutter_test/flutter_test.dart';
import 'package:tide_forecast_app/features/diagnostic/suites/stations_topology_suite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('【功能 02 真實穿透自檢】85 測站資產在庫、地理包圍盒與水文分類實體審計', () async {
    final result = await StationsTopologyDiagnosticSuite.run();

    print("\n╔══════════════════════════════════════════════════════════════╗");
    print("║   🔍 【功能 02 專項自檢：85 測站資產與空間坐標實體審計】        ║");
    print("╠══════════════════════════════════════════════════════════════╣");
    print("║ • 資產在線 : ${result.isStationCountValid ? '✅ 完整' : '❌ 缺失'} (${result.totalStations}/85 站)");
    print("║ • 坐標包圍 : ${result.isBoundingBoxValid ? '✅ 零壞死' : '❌ 異常'} (${result.zeroCoordsCount} 個 0.0 壞死坐標)");
    print("║ • 地名轉譯 : ${result.isFuguiMapped ? '✅ 通過' : '❌ 失敗'} (${result.fuguiStationName})");
    print("║ • 海域平衡 : ${result.isRegionsBalanced ? '✅ 合規' : '❌ 失衡'} (${result.regionCounts})");
    print("║ • 水文型態 : ${result.isStationTypesValid ? '✅ 精確' : '❌ 錯誤'} (${result.buoyCount} 浮標 • ${result.tideCount} 潮位站)");
    print("║ • 審計結論 : ${result.message}");
    print("╚══════════════════════════════════════════════════════════════╝\n");

    expect(result.isFileLoaded, isTrue, reason: "assets/stations_config.json 必須存在且可讀取");
    expect(result.isStationCountValid, isTrue, reason: "測站總數必須為 85 站");
    expect(result.isBoundingBoxValid, isTrue, reason: "全島 85 站經緯度嚴禁為 0.0 且不得超出台灣海域");
    expect(result.isFuguiMapped, isTrue, reason: "C6AH2 必須正確綁定為富貴角北部資料浮標");
    expect(result.isRegionsBalanced, isTrue, reason: "五大海域分佈必須為 北11、西41、南9、東10、離島14");
    expect(result.isStationTypesValid, isTrue, reason: "水文分類必須剛好為 23 座浮標與 62 座潮位站");
  });
}
