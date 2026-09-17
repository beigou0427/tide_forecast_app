import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/tide_model.dart';
import '../domain/tide_repository.dart';
import '../data/tide_repository_impl.dart';
import '../../../core/network/tide_api_service.dart';
import '../../../core/utils/constants.dart';

final tideApiServiceProvider = Provider((ref) => TideApiService());

/// 🌟 這裡不再是回傳 Null，而是連接實作
final tideRepositoryProvider = Provider<TideRepository>((ref) {
  final api = ref.watch(tideApiServiceProvider);
  return TideRepositoryImpl(api);
});

/// 🌟 恢復收藏清單 Provider
final favoriteStationsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(tideRepositoryProvider).getFavoriteStations();
});

final currentStationIdProvider = StateProvider<String>((ref) => "46694A");
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
  double minDistance = double.infinity;
  String? nearestId;
  for (var station in AppConstants.allStations) {
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
  final repo = ref.watch(tideRepositoryProvider);
  final stationId = ref.watch(currentStationIdProvider);
  final locationAsync = ref.watch(userLocationProvider);

  try {
    final TideStationData stationData = await repo.getTideData(stationId);
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
    return TideViewData(stationData: stationData, distanceKm: distance, selectedDate: ref.read(selectedDateProvider));
  } catch (e) { rethrow; }
});
