import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../data/tide_model.dart';
import '../domain/tide_repository.dart';
import '../data/tide_repository_impl.dart';
import '../../../core/network/tide_api_service.dart';
import '../../../core/utils/constants.dart';

/// 1. 提供 API 服務實例
final tideApiServiceProvider = Provider((ref) => TideApiService());

/// 2. 提供 Repository 實例 (封裝業務邏輯與 API 調度)
final tideRepositoryProvider = Provider<TideRepository>((ref) {
  final api = ref.watch(tideApiServiceProvider);
  return TideRepositoryImpl(api);
});

/// 3. 提供收藏測站 ID 清單 (自動監聽本地儲存)
final favoriteStationsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(tideRepositoryProvider).getFavoriteStations();
});

/// 4. 追蹤目前選擇的測站 ID
final currentStationIdProvider = StateProvider<String>((ref) => "46694A");

/// 5. 目前選擇的日期
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 6. 獲取使用者目前位置
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  } catch (e) {
    return null;
  }
});

/// 7. 自動計算最近測站
final nearestStationIdProvider = Provider<String?>((ref) {
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos == null) return null;
  double minDistance = double.infinity;
  String? nearestId;
  for (var station in AppConstants.allStations) {
    double distance = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, station.lat, station.lng);
    if (distance < minDistance) {
      minDistance = distance;
      nearestId = station.id;
    }
  }
  return nearestId;
});

/// 8. 綜合視圖模型
class TideViewData {
  final TideStationData stationData;
  final double? distanceKm;
  final DateTime selectedDate;
  TideViewData({required this.stationData, this.distanceKm, required this.selectedDate});
}

/// 9. 核心數據調度 Provider (重構為使用 Repository)
final tideViewDataProvider = FutureProvider<TideViewData>((ref) async {
  final repo = ref.watch(tideRepositoryProvider);
  final stationId = ref.watch(currentStationIdProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  final locationAsync = ref.watch(userLocationProvider);

  final now = DateTime.now();
  final String targetDateStr = DateFormat('yyyyMMdd').format(selectedDate);
  final String todayStr = DateFormat('yyyyMMdd').format(now);
  
  final bool isToday = targetDateStr == todayStr;
  final bool isFuture = selectedDate.isAfter(now) && !isToday;

  TideStationData stationData;

  try {
    if (isToday) {
      // [實時模式]：同時抓取即時海象與預報
      final results = await Future.wait([
        repo.getRealTimeData(stationId),
        repo.getForecastData(stationId),
      ]);
      final proxyData = results[0] as TideStationData;
      final fullForecastList = results[1] as List<TideForecast>;
      final dailyForecasts = fullForecastList.where((f) => 
        DateFormat('yyyyMMdd').format(f.dateTime) == targetDateStr).toList();

      stationData = TideStationData(
        info: proxyData.info,
        observations: proxyData.observations,
        forecasts: dailyForecasts,
      );
    } else if (isFuture) {
      // [遠期預報模式]
      final fullForecastList = await repo.getForecastData(stationId);
      final dailyForecasts = fullForecastList.where((f) => 
        DateFormat('yyyyMMdd').format(f.dateTime) == targetDateStr).toList();

      stationData = TideStationData(
        info: _getBasicStationInfo(stationId),
        observations: [], 
        forecasts: dailyForecasts,
      );
    } else {
      // [歷史回測模式]
      stationData = await repo.getHistoryData(stationId, selectedDate);
    }
  } catch (e) {
    rethrow;
  }

  // 計算距離
  double? distance;
  final userPos = locationAsync.value;
  if (userPos != null) {
    try {
      final sLat = double.tryParse(stationData.info.lat);
      final sLng = double.tryParse(stationData.info.lng);
      if (sLat != null && sLng != null && sLat != 0) {
        distance = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, sLat, sLng) / 1000;
      }
    } catch (_) {}
  }

  return TideViewData(stationData: stationData, distanceKm: distance, selectedDate: selectedDate);
});

StationInfo _getBasicStationInfo(String id) {
  final meta = AppConstants.allStations.firstWhere(
    (s) => s.id == id,
    orElse: () => StationModel(id: id, name: "未知站點", region: "未知", lat: 0, lng: 0),
  );
  return StationInfo(
    stationName: meta.name,
    countyName: meta.region,
    townName: "",
    lat: meta.lat.toString(),
    lng: meta.lng.toString(),
    attr: meta.isBuoy ? "資料浮標" : "潮位站",
    addressDescription: "預報模式",
  );
}
