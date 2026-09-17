import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/tide/data/tide_model.dart';

class TideApiService {
  // 🌟 最終正確網址格式 (檔案會被部署在倉庫的根路徑)
  static const String _baseUrl = "https://beigou0427.github.io/tide_forecast_app";

  Future<TideStationData> fetchRealTimeProxy(String stationId) async {
    try {
      final url = "$_baseUrl/edge_$stationId.json";
      print("DEBUG: 正在請求 -> $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return TideStationData.fromEdgeJson(jsonDecode(response.body));
      }
      throw Exception("資料尚未同步 (HTTP ${response.statusCode})");
    } catch (e) {
      print("🚨 載入失敗: $e");
      rethrow;
    }
  }
  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}
