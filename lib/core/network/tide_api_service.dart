import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  // 🌟 重要：請將 mingtong 換成你的 GitHub 帳號名稱
  // 網址格式：https://<帳號>.github.io/<倉庫名>/public/api/edge_<站點ID>.json
  static const String _baseUrl = "https://beigou0427.github.io/tide_forecast_app/public/api";

  Future<TideStationData> fetchRealTimeProxy(String stationId) async {
    try {
      final url = "$_baseUrl/edge_$stationId.json";
      print("DEBUG: 讀取邊緣數據 $url");
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return TideStationData.fromEdgeJson(jsonDecode(response.body));
      }
      throw Exception("數據同步中 (HTTP ${response.statusCode})");
    } catch (e) {
      print("🚨 Edge API 讀取失敗: $e");
      rethrow;
    }
  }

  // 預報功能暫時由後端整合在 JSON 中，前端維持空實作以避免編譯報錯
  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
