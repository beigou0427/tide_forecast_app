import 'package:shared_preferences/shared_preferences.dart';
import '../domain/tide_repository.dart';
import '../data/tide_model.dart';
import '../../../core/network/tide_api_service.dart';

class TideRepositoryImpl implements TideRepository {
  final TideApiService _apiService;
  static const String _favKey = "favorite_stations_v1";

  TideRepositoryImpl(this._apiService);

  @override
  Future<TideStationData> getTideData(String stationId) async {
    return await _apiService.fetchRealTimeProxy(stationId);
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
