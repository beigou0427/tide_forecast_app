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

// 🌟 Sundar Pichai L1 記憶體快速通道（防止 rootBundle 重複 I/O 解碼）
List<StationModel>? _memoryCachedStations;

// 85 站本地神盾資產庫
final stationListProvider = FutureProvider<List<StationModel>>((ref) async {
  if (_memoryCachedStations != null && _memoryCachedStations!.isNotEmpty) {
    return _memoryCachedStations!;
  }

  try {
    final localJsonStr = await rootBundle.loadString('assets/stations_config.json');
    final List localData = jsonDecode(localJsonStr);
    _memoryCachedStations = localData.map((e) => StationModel.fromJson(e)).toList();
    debugPrint("✅ [Google L1 快取] 85 測站權威拓撲裝載完畢，命中記憶體通道");
    return _memoryCachedStations!;
  } catch (e) {
    debugPrint("⚠️ 本地資產讀取異常，切換遠端備援: $e");
    try {
      final response = await http.get(Uri.parse(AppConstants.remoteStationsUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _memoryCachedStations = data.map((e) => StationModel.fromJson(e)).toList();
        return _memoryCachedStations!;
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
    } catch (_) {
    } finally {
      // 🌟 保證在 state 寫入完全就緒後，一次性翻轉初始化標誌
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

// 🌟 Sundar Pichai 空間防抖記憶體（實裝 85 站全量驗證防禦）
Position? _lastEvaluatedPosition;
String? _lastNearestStationId;
int _lastEvaluatedStationCount = 0;

final nearestStationIdProvider = Provider<String?>((ref) {
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos == null) return null;

  final stations = ref.watch(stationListProvider).value;
  
  // 🚨 核心防線：唯有當全島完整 85 站（至少 >= 80 站）完全加載就緒時，才進行最近測站計算！
  // 嚴禁使用 2 席北部備援站先行計算，徹底粉碎全台釣友被鎖死在淡水的空間死鎖！
  if (stations == null || stations.length < 80) {
    return null;
  }

  // 空間防抖：僅在同一定位且測站庫完整度未變更時，若移動小於 300 公尺才命中快取
  if (_lastEvaluatedPosition != null && 
      _lastNearestStationId != null && 
      _lastEvaluatedStationCount == stations.length) {
    final movedDistance = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude,
      _lastEvaluatedPosition!.latitude, _lastEvaluatedPosition!.longitude
    );
    if (movedDistance < 300.0) {
      return _lastNearestStationId;
    }
  }
  
  double minDistance = double.infinity;
  String? nearestId;
  for (var station in stations) {
    // 嚴格過濾 Null Island (0,0) 與偏離台灣海域的噪訊坐標
    if (station.lat < 20.0 || station.lat > 28.0 || station.lng < 116.0 || station.lng > 124.0) continue;
    double d = Geolocator.distanceBetween(userPos.latitude, userPos.longitude, station.lat, station.lng);
    if (d < minDistance) { 
      minDistance = d; 
      nearestId = station.id; 
    }
  }

  _lastEvaluatedPosition = userPos;
  _lastNearestStationId = nearestId;
  _lastEvaluatedStationCount = stations.length;
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

  // 若開機偏好尚未完成讀取，暫緩等待響應式觸發，不發送多餘預設站點請求
  if (!isInit) {
    return Completer<TideViewData>().future;
  }

  final api = ref.watch(tideApiServiceProvider);
  final locationAsync = ref.watch(userLocationProvider);
  final isPremium = ref.watch(premiumProvider).isPremium;
  final activeDate = ref.watch(selectedDateProvider);

  try {
    final TideStationData stationData = await api.fetchData(stationId, isPremium: isPremium);
    double? distance;
    final userPos = locationAsync.value;
    if (userPos != null) {
      try {
        final sLat = double.tryParse(stationData.info.lat);
        final sLng = double.tryParse(stationData.info.lng);
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
      selectedDate: activeDate,
    );
  } catch (e) { 
    rethrow; 
  }
});
