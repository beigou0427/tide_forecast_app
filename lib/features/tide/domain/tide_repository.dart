import '../data/tide_model.dart';

/// 潮汐數據倉庫介面
/// 定義了 App 核心業務邏輯所需的所有數據行為
abstract class TideRepository {
  
  /// 獲取實時海象數據 (代理 API)
  /// [stationId] 測站編號
  Future<TideStationData> getRealTimeData(String stationId);

  /// 獲取 30 天歷史回測數據 (官方 API)
  /// [stationId] 測站編號
  /// [targetDate] 目標日期
  Future<TideStationData> getHistoryData(String stationId, DateTime targetDate);

  /// 獲取未來潮汐預報 (官方 API)
  /// [stationId] 測站編號
  Future<List<TideForecast>> getForecastData(String stationId);
  
  /// 獲取使用者最愛的測站清單
  Future<List<String>> getFavoriteStations();
  
  /// 切換測站收藏狀態
  Future<void> toggleFavorite(String stationId);
}
