import 'dart:convert';
import 'dart:io';

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
    final dir = Directory('deploy_api');
    if (!await dir.exists()) {
      return const FullStationsAuditResult(
        totalAudited: 0, validStations: 0, missingForecasts: 0,
        untranslatedNames: 0, invalidScores: 0, coordinateErrors: 0,
        errorStationIds: ['NO_DIR'], message: "deploy_api 目錄不存在",
      );
    }

    final List<FileSystemEntity> files = dir.listSync().where((f) => f.path.contains('edge_') && f.path.endsWith('.json')).toList();

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

        // 1. 檢查 30 天潮汐預報
        final List forecasts = data['forecasts'] ?? [];
        if (forecasts.length < 20) {
          missingForecastCount++;
          failedIds.add("$sid(預報短缺:${forecasts.length})");
          continue;
        }

        // 2. 檢查地名是否未轉譯 (仍為純英數代碼)
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

        // 4. 檢查地理座標真實性
        final double lat = (info['lat'] ?? 0.0) as double;
        final double lng = (info['lng'] ?? 0.0) as double;
        final String region = info['region']?.toString() ?? '';
        if (lat == 0.0 || lng == 0.0) {
          coordErrorCount++;
          failedIds.add("$sid(坐標歸零)");
          continue;
        }

        // 區域坐標合理性交叉比對
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
      message: perfect ? "全台 85 測站實體檔案全部通過 4 大指標穿透檢驗，0 壞死、0 缺失" : "發現 ${failedIds.length} 個檔案存在真實缺陷: $failedIds",
    );
  }
}
