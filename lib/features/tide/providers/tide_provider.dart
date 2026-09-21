import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../data/tide_model.dart';
import '../domain/tide_repository.dart';
import '../data/tide_repository_impl.dart';
import '../../../core/network/tide_api_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/notification_service.dart';
import '../../premium/services/premium_service.dart';

final tideApiServiceProvider = Provider((ref) => TideApiService());

final tideRepositoryProvider = Provider<TideRepository>((ref) {
  final api = ref.watch(tideApiServiceProvider);
  return TideRepositoryImpl(api);
});

final favoriteStationsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(tideRepositoryProvider).getFavoriteStations();
});

// 🌟 核心防禦：優先從本地內嵌資產載入 85 站權威拓撲，杜絕雲端快取污染
final stationListProvider = FutureProvider<List<StationModel>>((ref) async {
  try {
    final localJsonStr = await rootBundle.loadString('assets/stations_config.json');
    final List localData = jsonDecode(localJsonStr);
    debugPrint("✅ [本地神盾] 成功載入 ${localData.length} 個權威測站拓撲 (北部11, 西部41, 南部9, 東部10, 離島14)");
    return localData.map((e) => StationModel.fromJson(e)).toList();
  } catch (e) {
    debugPrint("⚠️ 本地資產讀取異常，切換遠端備用: $e");
    try {
      final response = await http.get(Uri.parse(AppConstants.remoteStationsUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => StationModel.fromJson(e)).toList();
      }
    } catch (_) {}
  }
  return AppConstants.fallbackStations;
});

final currentStationIdProvider = StateProvider<String>((ref) => "C6AH2");
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

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
  } catch (e) { return null; }
});

final nearestStationIdProvider = Provider<String?>((ref) {
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos == null) return null;
  
  final stations = ref.watch(stationListProvider).value ?? AppConstants.fallbackStations;
  
  double minDistance = double.infinity;
  String? nearestId;
  for (var station in stations) {
    double d = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, station.lat, station.lng);
    if (d < minDistance) { minDistance = d; nearestId = station.id; }
  }
  return nearestId;
});

class TideViewData {
  final TideStationData stationData;
  final double? distanceKm;
  final DateTime selectedDate;
  TideViewData({required this.stationData, this.distanceKm, required this.selectedDate});
}

final tideViewDataProvider = FutureProvider<TideViewData>((ref) async {
  final api = ref.watch(tideApiServiceProvider);
  final stationId = ref.watch(currentStationIdProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final isPremium = ref.watch(premiumProvider).isPremium;

  try {
    final TideStationData stationData = await api.fetchData(stationId, isPremium: isPremium);
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

    ReviewService.checkAndTriggerReview();

    final now = DateTime.now();
    for (final f in stationData.forecasts) {
      if (f.tideType.contains('滿') && f.dateTime.isAfter(now)) {
        NotificationService.scheduleTideSurgeAlert(
          highTideTime: f.dateTime,
          stationName: stationData.info.stationName,
        );
        break;
      }
    }

    return TideViewData(stationData: stationData, distanceKm: distance, selectedDate: ref.read(selectedDateProvider));
  } catch (e) { rethrow; }
});
