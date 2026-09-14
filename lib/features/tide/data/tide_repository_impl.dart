import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/tide_repository.dart';
import '../../tide/data/tide_model.dart';
import '../../../core/network/tide_api_service.dart';

class TideRepositoryImpl implements TideRepository {
  final TideApiService _apiService;
  static const String _favKey = "favorite_stations";

  TideRepositoryImpl(this._apiService);

  @override
  Future<TideStationData> getRealTimeData(String stationId) async {
    // 呼叫代理 API 獲取即時數據
    return await _apiService.fetchRealTimeProxy(stationId);
  }

  @override
  Future<TideStationData> getHistoryData(String stationId, DateTime targetDate) async {
    // 格式化日期為氣象署要求的格式 (yyyy-MM-ddT00:00:00)
    final String start = "${DateFormat('yyyy-MM-dd').format(targetDate)}T00:00:00";
    final String end = "${DateFormat('yyyy-MM-dd').format(targetDate)}T23:59:59";
    
    return await _apiService.fetchHistoryOfficial(stationId, start, end);
  }

  @override
  Future<List<TideForecast>> getForecastData(String stationId) async {
    // 獲取未來滿乾潮預報
    return await _apiService.fetchForecastOfficial(stationId);
  }

  @override
  Future<List<String>> getFavoriteStations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favKey) ?? [];
  }

  @override
  Future<void> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favKey) ?? [];

    if (favorites.contains(stationId)) {
      favorites.remove(stationId);
    } else {
      favorites.add(stationId);
    }

    await prefs.setStringList(_favKey, favorites);
  }
}
