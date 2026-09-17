import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  // 🌟 核心修正：對齊 GitHub Pages 部署後的真實網址 (移除 public/)
  static const String _baseUrl = "https://beigou0427.github.io/tide_forecast_app/api";

  Future<TideStationData> fetchRealTimeProxy(String stationId) async {
    try {
      final url = "$_baseUrl/edge_$stationId.json";
      print("DEBUG: 正在從邊緣節點請求 -> $url");

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return TideStationData.fromEdgeJson(jsonDecode(response.body));
      }
      throw Exception("資料尚未就緒 (HTTP ${response.statusCode})");
    } catch (e) {
      print("🚨 邊緣數據讀取失敗: $e");
      rethrow;
    }
  }

  // 歷史與預報數據目前整合於邊緣 JSON 中，前端保留介面以利未來擴充
  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
