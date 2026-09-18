import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  static const String _edgeUrl = "https://beigou0427.github.io/tide_forecast_app";

  Future<TideStationData> fetchData(String stationId, {bool isPremium = false}) async {
    try {
      // 1. 所有人：先去 GitHub 拿預運算的靜態資料
      final t = DateTime.now().millisecondsSinceEpoch;
      final edgeResponse = await http.get(Uri.parse("$_edgeUrl/edge_$stationId.json?t=$t")).timeout(const Duration(seconds: 5));
      
      Map<String, dynamic> edgeJson = {};
      if (edgeResponse.statusCode == 200) {
        edgeJson = jsonDecode(edgeResponse.body);
      }

      // 如果是免費版，直接回傳 Edge 資料
      if (!isPremium) {
        if (edgeJson.isEmpty) throw Exception("伺服器維護中");
        return TideStationData.fromEdgeJson(edgeJson);
      }

      // 🌟 2. VIP 付費用戶：向氣象署請求絕對即時數據
      try {
        print("💎 VIP 啟動：向氣象署請求絕對即時數據...");
        final cwaUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=${AppConstants.officialApiKey}&StationID=$stationId";
        final cwaResponse = await http.get(Uri.parse(cwaUrl)).timeout(const Duration(seconds: 5));
        
        if (cwaResponse.statusCode == 200) {
          final cwaData = jsonDecode(cwaResponse.body);
          final records = cwaData['Records'] ?? cwaData['records'];
          final realtimeObs = records['Location'][0];
          
          final mergedJson = {
            "obs": realtimeObs,
            "ai_expert": edgeJson['ai_expert'] ?? {"briefing": "AI 簡報更新中", "safety_score": 85, "activities": []}
          };
          print("✅ VIP 即時數據融合成功！");
          return TideStationData.fromEdgeJson(mergedJson);
        }
      } catch (cwaError) {
        print("⚠️ VIP 即時請求超時，降級使用 Edge 數據: $cwaError");
      }

      return TideStationData.fromEdgeJson(edgeJson);

    } catch (e) {
      print("🚨 API 服務中斷: $e");
      rethrow;
    }
  }

  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
