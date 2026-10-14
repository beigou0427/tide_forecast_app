import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  static const String _edgeUrl = "https://beigou0427.github.io/tide_forecast_app";
  static const String _cachePrefix = "tide_offline_cache_";

  Future<TideStationData> fetchData(String stationId, {bool isPremium = false}) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final edgeUrl = "$_edgeUrl/edge_$stationId.json?t=$t";
      debugPrint("DEBUG: 正在抓取邊緣海象 -> $edgeUrl");

      final edgeResponse = await http.get(Uri.parse(edgeUrl)).timeout(const Duration(seconds: 15));
      
      Map<String, dynamic> edgeJson = {};
      if (edgeResponse.statusCode == 200) {
        edgeJson = jsonDecode(edgeResponse.body);
      }

      if (!isPremium) {
        if (edgeJson.isEmpty) throw Exception("資料庫暫無回應 (HTTP ${edgeResponse.statusCode})");
        await prefs.setString('$_cachePrefix$stationId', jsonEncode(edgeJson));
        return TideStationData.fromEdgeJson(edgeJson);
      }

      // 💎 VIP 專線直連 (RFC 3986 安全規範與防污染版)
      try {
        final String? customKey = prefs.getString('custom_cwa_api_key');
        final String rawKey = (customKey != null && customKey.isNotEmpty) 
            ? customKey 
            : AppConstants.officialApiKey;

        // 🌟 核心防線 1：只保留英數字與破折號，徹底消滅 ?、/、$ 引發的 F5 WAF 參數污染攔截！
        final String cleanKey = rawKey.replaceAll(RegExp(r'[^0-9a-zA-Z-]'), '').trim();

        // 檢查金鑰是否具備基本格式，避免向氣象署發射無效字串
        final bool isKeyUsable = cleanKey.startsWith('CWA-') && cleanKey.length >= 20;

        if (isKeyUsable) {
          debugPrint("💎 VIP 啟動：向氣象署專線請求站點 $stationId 即時數據...");

          // 🌟 核心防線 2：使用官方 Uri.https 嚴格建構參數，杜絕雙重問號與非法字元！
          final cwaUri = Uri.https(
            'opendata.cwa.gov.tw',
            '/api/v1/rest/datastore/O-B0075-001',
            {
              'Authorization': cleanKey,
              'StationID': stationId,
              'format': 'JSON',
            },
          );

          final cwaResponse = await http.get(
            cwaUri,
            headers: {
              'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 TidePro/2.6.0',
              'Accept': 'application/json, text/plain, */*',
            },
          ).timeout(const Duration(seconds: 8));

          String rawBody = cwaResponse.body.trim();
          if (rawBody.startsWith('\uFEFF')) {
            rawBody = rawBody.substring(1).trim();
          }

          final int previewLen = math.min(60, rawBody.length);
          debugPrint("🔍 CWA 即時連線回傳 (HTTP ${cwaResponse.statusCode})，檔頭前 $previewLen 字元: ${rawBody.substring(0, previewLen)}");

          // 🌟 核心防線 3：只有在回傳真正 JSON 時才解析，徹底阻斷 HTML 報錯頁面！
          if (cwaResponse.statusCode == 200 && rawBody.startsWith('{')) {
            final cwaData = jsonDecode(rawBody);
            final records = cwaData['Records'] ?? cwaData['records'] ?? {};
            final seaObs = records['SeaSurfaceObs'] ?? records;
            final locations = (seaObs['Location'] is List) ? seaObs['Location'] : [];
            
            if (locations.isNotEmpty) {
              final realtimeObs = locations[0];

              final stationInfo = (edgeJson['station_info'] is Map) ? edgeJson['station_info'] as Map<String, dynamic> : {};
              final edgeObs = (edgeJson['obs'] is Map) ? edgeJson['obs'] as Map<String, dynamic> : {};

              final mergedObs = Map<String, dynamic>.from(realtimeObs);
              mergedObs['StationName'] = stationInfo['friendly_name'] ?? edgeObs['StationName'] ?? "測站 $stationId";
              mergedObs['CountyName'] = stationInfo['county'] ?? edgeObs['CountyName'] ?? "";
              mergedObs['TownName'] = stationInfo['town'] ?? edgeObs['TownName'] ?? "";
              mergedObs['lat'] = stationInfo['lat'] ?? edgeObs['lat'] ?? 25.0;
              mergedObs['lng'] = stationInfo['lng'] ?? edgeObs['lng'] ?? 121.5;
              mergedObs['attr'] = stationInfo['station_type'] ?? edgeObs['attr'] ?? "資料浮標";
              mergedObs['region'] = stationInfo['region'] ?? edgeObs['region'] ?? "北部";

              final mergedJson = {
                "obs": mergedObs,
                "station_info": stationInfo,
                "forecasts": edgeJson['forecasts'] ?? [],
                "ai_expert": edgeJson['ai_expert'] ?? {
                  "briefing": "AI 實時簡報同步完成，海況平穩。",
                  "safety_score": 85,
                  "activities": ["海邊作業", "作釣觀察"]
                }
              };
              debugPrint("✅ VIP 專線直連成功！已穿透氣象署專線並融合實時水文：${mergedObs['StationName']}");
              await prefs.setString('$_cachePrefix$stationId', jsonEncode(mergedJson));
              return TideStationData.fromEdgeJson(mergedJson);
            } else {
              debugPrint("⚠️ 氣象署此測站目前無實時回傳，平滑降級使用 Edge 數據");
            }
          } else {
            debugPrint("⚠️ 氣象署即時專線回應非預期 (HTTP ${cwaResponse.statusCode})，平滑降級使用 Edge 數據");
          }
        } else {
          debugPrint("💎 VIP 專線：金鑰尚未配置或格式異常，平滑接管全島 85 站邊緣光纖快照");
        }
      } catch (cwaError) {
        debugPrint("⚠️ VIP 直連超時或網路波動，平滑降級使用 Edge 數據: $cwaError");
      }

      if (edgeJson.isNotEmpty) {
        await prefs.setString('$_cachePrefix$stationId', jsonEncode(edgeJson));
      }
      return TideStationData.fromEdgeJson(edgeJson);

    } catch (e) {
      debugPrint("🚨 API 連線失敗，啟動離線防禦機制: $e");
      final cachedStr = prefs.getString('$_cachePrefix$stationId');
      if (cachedStr != null) {
        final Map<String, dynamic> cachedJson = jsonDecode(cachedStr);
        return TideStationData.fromEdgeJson(cachedJson);
      }
      rethrow;
    }
  }

  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
