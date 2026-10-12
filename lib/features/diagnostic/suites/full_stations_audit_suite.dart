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

          final List forecasts = data['forecasts'] ?? [];
          if (forecasts.length < 20) {
            missingForecastCount++;
            failedIds.add("$sid(預報短缺:${forecasts.length})");
            continue;
          }

          final info = data['station_info'] ?? {};
          final String name = info['friendly_name']?.toString() ?? data['obs']?['StationName']?.toString() ?? '';
          final bool isRawCode = name == sid || !name.contains(RegExp(r'[\u4e00-\u9fff]'));
          if (name.isEmpty || isRawCode) {
            untranslatedCount++;
            failedIds.add("$sid(地名未轉譯:$name)");
            continue;
          }

          final ai = data['ai_expert'] ?? {};
          final score = (ai['safety_score'] ?? -1) as num;
          if (score < 0 || score > 100) {
            invalidScoreCount++;
            failedIds.add("$sid(安全分溢出:$score)");
            continue;
          }

          // 🚨 核心防線：安全解析字串與數字混用的 JSON 欄位，杜絕 TypeError as double 崩潰！
          final rawLat = info['lat'] ?? 0.0;
          final rawLng = info['lng'] ?? 0.0;
          final double lat = rawLat is num ? rawLat.toDouble() : (double.tryParse(rawLat.toString()) ?? 0.0);
          final double lng = rawLng is num ? rawLng.toDouble() : (double.tryParse(rawLng.toString()) ?? 0.0);
          
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
        
        // 🚨 安全型別轉換防護
        final rawLat = s['lat'] ?? 0.0;
        final rawLng = s['lng'] ?? 0.0;
        final double lat = rawLat is num ? rawLat.toDouble() : (double.tryParse(rawLat.toString()) ?? 0.0);
        final double lng = rawLng is num ? rawLng.toDouble() : (double.tryParse(rawLng.toString()) ?? 0.0);
        
        final String region = s['region']?.toString() ?? '';

        final bool isRawCode = name == sid || !name.contains(RegExp(r'[\u4e00-\u9fff]'));
        if (name.isEmpty || isRawCode) {
          untranslatedCount++;
          failedIds.add("$sid(未轉譯:$name)");
          continue;
        }

        if (lat < 20.0 || lat > 27.5 || lng < 116.0 || lng > 124.0) {
          coordErrorCount++;
          failedIds.add("$sid(坐標越界:[$lat,$lng])");
          continue;
        }

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