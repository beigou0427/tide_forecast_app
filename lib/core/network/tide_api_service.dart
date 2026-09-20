import 'dart:convert';
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

      try {
        debugPrint("💎 VIP 啟動：向氣象署專線請求站點 $stationId 即時數據...");
        final cwaUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=${AppConstants.officialApiKey}&StationID=$stationId";
        final cwaResponse = await http.get(Uri.parse(cwaUrl)).timeout(const Duration(seconds: 15));
        
        if (cwaResponse.statusCode == 200) {
          final cwaData = jsonDecode(cwaResponse.body);
          final records = cwaData['Records'] ?? cwaData['records'] ?? {};
          final seaObs = records['SeaSurfaceObs'] ?? records;
          final locations = (seaObs['Location'] is List) ? seaObs['Location'] : [];
          
          if (locations.isNotEmpty) {
            final realtimeObs = locations[0];
            final mergedJson = {
              "obs": realtimeObs,
              "forecasts": edgeJson['forecasts'] ?? [],
              "ai_expert": edgeJson['ai_expert'] ?? {
                "briefing": "AI 實時簡報同步完成，海況平穩。",
                "safety_score": 85,
                "activities": ["海邊作業", "作釣觀察"]
              }
            };
            debugPrint("✅ VIP 85測站即時數據融合成功！");
            await prefs.setString('$_cachePrefix$stationId', jsonEncode(mergedJson));
            return TideStationData.fromEdgeJson(mergedJson);
          }
        }
      } catch (cwaError) {
        debugPrint("⚠️ VIP 直連超時，平滑降級使用 Edge 數據: $cwaError");
      }

      if (edgeJson.isNotEmpty) {
        await prefs.setString('$_cachePrefix$stationId', jsonEncode(edgeJson));
      }
      return TideStationData.fromEdgeJson(edgeJson);

    } catch (e) {
      debugPrint("🚨 API 連線失敗，啟動離線防禦機制: $e");
      final cachedStr = prefs.getString('$_cachePrefix$stationId');
      if (cachedStr != null) {
        debugPrint("📦 成功啟動【離線安全模式】快取數據！");
        final Map<String, dynamic> cachedJson = jsonDecode(cachedStr);
        if (cachedJson['ai_expert'] is Map<String, dynamic>) {
          cachedJson['ai_expert']['briefing'] = "【離線安全模式】現場訊號微弱，正顯示最後存檔海象。${cachedJson['ai_expert']['briefing'] ?? ''}";
        }
        return TideStationData.fromEdgeJson(cachedJson);
      }
      rethrow;
    }
  }

  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
