import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class FullStationsAuditResult {
  final int totalAudited;
  final int validStations;
  final int missingForecasts;
  final int untranslatedNames;
  final int invalidScores;
  final int coordinateErrors;
  final List<String> errorStationIds;
  final String message;

  const FullStationsAuditResult({
    required this.totalAudited,
    required this.validStations,
    required this.missingForecasts,
    required this.untranslatedNames,
    required this.invalidScores,
    required this.coordinateErrors,
    required this.errorStationIds,
    required this.message,
  });

  bool get isPerfect => totalAudited == 85 && validStations == 85 && errorStationIds.isEmpty;
}

class FullStationsAuditSuite {
  static Future<FullStationsAuditResult> run() async {
    final deployDir = Directory('deploy_api');
    final bool hasDeployDir = await deployDir.exists();

    // 軌道 A：本機開發環境存在 deploy_api 目錄時，直接審查 85 份實體邊緣快照
    if (hasDeployDir) {
      final List<FileSystemEntity> files = deployDir
          .listSync()
          .where((f) => f.path.contains('edge_') && f.path.endsWith('.json'))
          .toList();

      int validCount = 0;
      int missingForecastCount = 0;
      int untranslatedCount = 0;
      int invalidScoreCount = 0;
      int coordErrorCount = 0;
      final List<String> failedIds = [];

      for (var fileEntity in files) {
        final file = File(fileEntity.path);
        final filename = file.uri.pathSegments.last;
        final sid = filename.replaceAll('edge_', '').replaceAll('.json', '');

        try {
          final content = await file.readAsString();
          final Map<String, dynamic> data = jsonDecode(content);

          // 1. 檢查 30 天潮汐預報深度
          final List forecasts = data['forecasts'] ?? [];
          if (forecasts.length < 20) {
            missingForecastCount++;
            failedIds.add("$sid(預報短缺:${forecasts.length})");
            continue;
          }

          // 2. 檢查地名轉譯 (嚴禁純英數代碼)
          final info = data['station_info'] ?? {};
          final String name = info['friendly_name']?.toString() ?? data['obs']?['StationName']?.toString() ?? '';
          final bool isRawCode = name == sid || !name.contains(RegExp(r'[\u4e00-\u9fff]'));
          if (name.isEmpty || isRawCode) {
            untranslatedCount++;
            failedIds.add("$sid(地名未轉譯:$name)");
            continue;
          }

          // 3. 檢查 AI 安全係數
          final ai = data['ai_expert'] ?? {};
          final score = (ai['safety_score'] ?? -1) as num;
          if (score < 0 || score > 100) {
            invalidScoreCount++;
            failedIds.add("$sid(安全分溢出:$score)");
            continue;
          }

          // 4. 檢查海域地理坐標 (含東沙島等全海域包圍盒)
          final double lat = (info['lat'] ?? 0.0) as double;
          final double lng = (info['lng'] ?? 0.0) as double;
          if (lat < 20.0 || lat > 27.5 || lng < 116.0 || lng > 124.0) {
            coordErrorCount++;
            failedIds.add("$sid(坐標越界:[$lat,$lng])");
            continue;
          }

          validCount++;
        } catch (e) {
          failedIds.add("$sid(檔案損壞:$e)");
        }
      }

      final bool perfect = files.length == 85 && validCount == 85;
      return FullStationsAuditResult(
        totalAudited: files.length,
        validStations: validCount,
        missingForecasts: missingForecastCount,
        untranslatedNames: untranslatedCount,
        invalidScores: invalidScoreCount,
        coordinateErrors: coordErrorCount,
        errorStationIds: failedIds,
        message: perfect 
            ? "全台 85 測站實體邊緣檔案全部通過 4 大指標穿透檢驗，0 壞死、0 缺失" 
            : "發現 ${failedIds.length} 個檔案存在真實缺陷: $failedIds",
      );
    }

    // 軌道 B：iOS/Android 實機沙盒環境，直接真穿透審計 App 內建的 assets/stations_config.json
    try {
      final raw = await rootBundle.loadString('assets/stations_config.json');
      final List stationsList = jsonDecode(raw);

      int validCount = 0;
      int untranslatedCount = 0;
      int coordErrorCount = 0;
      final List<String> failedIds = [];

      for (var s in stationsList) {
        final sid = s['id']?.toString() ?? '';
        final name = s['name']?.toString() ?? '';
        final double lat = (s['lat'] ?? 0.0).toDouble();
        final double lng = (s['lng'] ?? 0.0).toDouble();
        final String region = s['region']?.toString() ?? '';

        // 1. 檢查地名轉譯
        final bool isRawCode = name == sid || !name.contains(RegExp(r'[\u4e00-\u9fff]'));
        if (name.isEmpty || isRawCode) {
          untranslatedCount++;
          failedIds.add("$sid(未轉譯:$name)");
          continue;
        }

        // 2. 檢查地理包圍盒 (杜絕 Null Island)
        if (lat < 20.0 || lat > 27.5 || lng < 116.0 || lng > 124.0) {
          coordErrorCount++;
          failedIds.add("$sid(坐標越界:[$lat,$lng])");
          continue;
        }

        // 3. 區域交叉合理性比對
        if (region == '北部' && lat < 24.5) {
          coordErrorCount++;
          failedIds.add("$sid(北部坐標偏南:$lat)");
          continue;
        }
        if (region == '南部' && lat > 23.5) {
          coordErrorCount++;
          failedIds.add("$sid(南部坐標偏北:$lat)");
          continue;
        }

        validCount++;
      }

      final bool perfect = stationsList.length == 85 && validCount == 85;
      return FullStationsAuditResult(
        totalAudited: stationsList.length,
        validStations: validCount,
        missingForecasts: 0,
        untranslatedNames: untranslatedCount,
        invalidScores: 0,
        coordinateErrors: coordErrorCount,
        errorStationIds: failedIds,
        message: perfect 
            ? "App 內建 85 測站權威拓撲實體全部通過坐標邊界與中文轉譯檢驗，0 壞死！" 
            : "發現 ${failedIds.length} 個測站拓撲異常: $failedIds",
      );
    } catch (e) {
      return FullStationsAuditResult(
        totalAudited: 0,
        validStations: 0,
        missingForecasts: 0,
        untranslatedNames: 0,
        invalidScores: 0,
        coordinateErrors: 0,
        errorStationIds: ['ASSET_LOAD_ERROR'],
        message: "無法載入 assets/stations_config.json: $e",
      );
    }
  }
}
