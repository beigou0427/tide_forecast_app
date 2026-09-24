import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class StationsTopologySuiteResult {
  final bool isFileLoaded;
  final bool isStationCountValid;
  final bool isBoundingBoxValid;
  final bool isFuguiMapped;
  final bool isRegionsBalanced;
  final bool isStationTypesValid;
  final int totalStations;
  final int zeroCoordsCount;
  final Map<String, int> regionCounts;
  final int buoyCount;
  final int tideCount;
  final String fuguiStationName;
  final String message;

  const StationsTopologySuiteResult({
    required this.isFileLoaded,
    required this.isStationCountValid,
    required this.isBoundingBoxValid,
    required this.isFuguiMapped,
    required this.isRegionsBalanced,
    required this.isStationTypesValid,
    required this.totalStations,
    required this.zeroCoordsCount,
    required this.regionCounts,
    required this.buoyCount,
    required this.tideCount,
    required this.fuguiStationName,
    required this.message,
  });

  bool get isAllPassed =>
      isFileLoaded &&
      isStationCountValid &&
      isBoundingBoxValid &&
      isFuguiMapped &&
      isRegionsBalanced &&
      isStationTypesValid;
}

class StationsTopologyDiagnosticSuite {
  static Future<StationsTopologySuiteResult> run() async {
    List<Map<String, dynamic>> stationsList = [];
    try {
      final raw = await rootBundle.loadString('assets/stations_config.json');
      stationsList = List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (e) {
      return StationsTopologySuiteResult(
        isFileLoaded: false,
        isStationCountValid: false,
        isBoundingBoxValid: false,
        isFuguiMapped: false,
        isRegionsBalanced: false,
        isStationTypesValid: false,
        totalStations: 0,
        zeroCoordsCount: 0,
        regionCounts: {},
        buoyCount: 0,
        tideCount: 0,
        fuguiStationName: "N/A",
        message: "無法讀取 assets/stations_config.json: $e",
      );
    }

    final int total = stationsList.length;
    final bool countValid = total == 85;

    int zeroCount = 0;
    int outOfBounds = 0;
    final Map<String, int> regions = {};
    int buoys = 0;
    int tides = 0;
    String fuguiName = "未找到";
    bool fuguiOk = false;

    for (var s in stationsList) {
      final sid = s['id']?.toString() ?? '';
      final name = s['name']?.toString() ?? '';
      final region = s['region']?.toString() ?? '未知';
      final lat = (s['lat'] ?? 0.0) as num;
      final lng = (s['lng'] ?? 0.0) as num;
      final bool isBuoy = s['isBuoy'] == true;

      if (lat == 0.0 || lng == 0.0) zeroCount++;
      if (lat < 20.0 || lat > 27.0 || lng < 116.0 || lng > 123.5) outOfBounds++;

      regions[region] = (regions[region] ?? 0) + 1;
      if (isBuoy) {
        buoys++;
      } else {
        tides++;
      }

      if (sid == 'C6AH2') {
        fuguiName = name;
        fuguiOk = name.contains('富貴角') && region == '北部' && lat > 25.0 && lng > 121.0;
      }
    }

    final bool boundingBoxOk = zeroCount == 0 && outOfBounds == 0;
    final bool regionsOk = (regions['北部'] == 11) &&
        (regions['西部'] == 41) &&
        (regions['南部'] == 9) &&
        (regions['東部'] == 10) &&
        (regions['離島'] == 14);
    final bool typesOk = (buoys == 23) && (tides == 62);

    String detailMsg;
    if (!countValid) {
      detailMsg = "測站數量短缺 (實測: $total/85)";
    } else if (!boundingBoxOk) {
      detailMsg = "發現 $zeroCount 個坐標壞死(0.0)或 $outOfBounds 個坐標越界";
    } else if (!fuguiOk) {
      detailMsg = "C6AH2 未正確轉譯為富貴角北部浮標 (目前名稱: $fuguiName)";
    } else if (!regionsOk) {
      detailMsg = "海域分區失衡: $regions";
    } else if (!typesOk) {
      detailMsg = "水文型態數量不符 (浮標: $buoys/23, 潮位: $tides/62)";
    } else {
      detailMsg = "85 站坐標零壞死、五大海域與 23 浮標/62 潮位站完全精準歸位";
    }

    return StationsTopologySuiteResult(
      isFileLoaded: true,
      isStationCountValid: countValid,
      isBoundingBoxValid: boundingBoxOk,
      isFuguiMapped: fuguiOk,
      isRegionsBalanced: regionsOk,
      isStationTypesValid: typesOk,
      totalStations: total,
      zeroCoordsCount: zeroCount,
      regionCounts: regions,
      buoyCount: buoys,
      tideCount: tides,
      fuguiStationName: fuguiName,
      message: detailMsg,
    );
  }
}
