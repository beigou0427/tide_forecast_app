import '../data/tide_model.dart';

abstract class TideRepository {
  /// 獲取雲端預運算的邊緣數據
  Future<TideStationData> getTideData(String stationId);
  
  /// 獲取收藏清單
  Future<List<String>> getFavoriteStations();
  
  /// 切換收藏狀態
  Future<void> toggleFavorite(String stationId);
}
