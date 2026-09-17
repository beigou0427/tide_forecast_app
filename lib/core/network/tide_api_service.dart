import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  // 🌟 對齊 GitHub Pages 根目錄網址
  static const String _baseUrl = "https://beigou0427.github.io/tide_forecast_app";

  Future<TideStationData> fetchRealTimeProxy(String stationId) async {
    try {
      final url = "$_baseUrl/edge_$stationId.json";
      print("DEBUG: 請求邊緣數據 -> $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return TideStationData.fromEdgeJson(jsonDecode(response.body));
      }
      throw Exception("資料未就緒 (HTTP ${response.statusCode})");
    } catch (e) {
      print("🚨 載入失敗: $e");
      rethrow;
    }
  }
  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
