import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/tide_model.dart';
import '../domain/tide_repository.dart';
import '../data/tide_repository_impl.dart';
import '../../../core/network/tide_api_service.dart';
import '../../../core/utils/constants.dart';
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

// 85 站本地神盾資產庫
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

// 啟動偏好就緒狀態標誌
final isStationInitializedProvider = StateProvider<bool>((ref) => false);

class CurrentStationNotifier extends Notifier<String> {
  @override
  String build() {
    _loadPreference();
    return "C6AH2";
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasInit = prefs.getBool('has_init_station') ?? false;
      
      if (!hasInit) {
        final region = prefs.getString('user_pref_region') ?? '';
        String targetId = "C6AH2";
        
        if (region.contains('北')) {
          targetId = "C6AH2";
        } else if (region.contains('西')) {
          targetId = "C4F01";
        } else if (region.contains('南')) {
          targetId = "C4P01";
        } else if (region.contains('東')) {
          targetId = "C4T01";
        } else if (region.contains('島')) {
          targetId = "C4W02";
        }
        
        state = targetId;
        await prefs.setBool('has_init_station', true);
        await prefs.setString('last_station_id', targetId);
      } else {
        final savedId = prefs.getString('last_station_id');
        if (savedId != null) {
          state = savedId;
        }
      }
    } catch (_) {} finally {
      ref.read(isStationInitializedProvider.notifier).state = true;
    }
  }

  @override
  set state(String value) {
    super.state = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('last_station_id', value);
    });
  }
}

final currentStationIdProvider = NotifierProvider<CurrentStationNotifier, String>(() {
  return CurrentStationNotifier();
});

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
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).timeout(const Duration(seconds: 4));
  } catch (_) { 
    return null; 
  }
});

final nearestStationIdProvider = Provider<String?>((ref) {
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos == null) return null;
  
  final stations = ref.watch(stationListProvider).value ?? AppConstants.fallbackStations;
  
  double minDistance = double.infinity;
  String? nearestId;
  for (var station in stations) {
    // 嚴格過濾 Null Island 與偏離台灣海域的無效坐標
    if (station.lat < 20.0 || station.lat > 28.0 || station.lng < 116.0 || station.lng > 124.0) continue;
    double d = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, station.lat, station.lng);
    if (d < minDistance) { 
      minDistance = d; 
      nearestId = station.id; 
    }
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
  final isInit = ref.watch(isStationInitializedProvider);
  final stationId = ref.watch(currentStationIdProvider);

  // 乾淨消滅 183 幀掉幀：若開機偏好尚未完成讀取，掛起等待響應式觸發，不發送多餘廢請求
  if (!isInit) {
    return Completer<TideViewData>().future;
  }

  final api = ref.watch(tideApiServiceProvider);
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
        // 核心地理防線：僅在坐標位於台灣周遭海域時才計算距離
        if (sLat != null && sLng != null && sLat >= 20.0 && sLat <= 28.0 && sLng >= 116.0 && sLng <= 124.0) {
          distance = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, sLat, sLng) / 1000;
        }
      } catch (_) {}
    }

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

    return TideViewData(
      stationData: stationData, 
      distanceKm: distance, 
      selectedDate: ref.read(selectedDateProvider),
    );
  } catch (e) { 
    rethrow; 
  }
});
