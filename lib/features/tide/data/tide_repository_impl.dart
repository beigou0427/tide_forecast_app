import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/tide_repository.dart';
import '../data/tide_model.dart';
import '../../../core/network/tide_api_service.dart';

/// 🌟 Rob Pike (Go 語言之父 / Unix 傳奇) 簡素高吞吐水文倉儲實作
/// 導入 L1 記憶體原子快取 (Write-Through Cache)，徹底消除重複磁碟 I/O 競爭
class TideRepositoryImpl implements TideRepository {
  final TideApiService _apiService;
  static const String _favKey = "favorite_stations_v1";

  // 🌟 Rob Pike L1 記憶體常駐快取：0ms 查詢，消滅每次請求重複獲取 SharedPreferences 實例
  Set<String>? _memoryFavorites;

  TideRepositoryImpl(this._apiService);

  @override
  Future<TideStationData> getTideData(String stationId) async {
    return await _apiService.fetchData(stationId);
  }

  @override
  Future<List<String>> getFavoriteStations() async {
    if (_memoryFavorites != null) {
      return _memoryFavorites!.toList();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favKey) ?? [];
      _memoryFavorites = Set<String>.from(list);
      return _memoryFavorites!.toList();
    } catch (e) {
      debugPrint("⚠️ [Rob Pike 倉儲] 讀取最愛磁碟失敗，回退空集: $e");
      return [];
    }
  }

  @override
  Future<void> toggleFavorite(String stationId) async {
    // 確保記憶體快取已就緒
    if (_memoryFavorites == null) {
      await getFavoriteStations();
    }

    // 🌟 原子化記憶體更新 (0ms 立即響應 UI)
    if (_memoryFavorites!.contains(stationId)) {
      _memoryFavorites!.remove(stationId);
    } else {
      _memoryFavorites!.add(stationId);
    }

    // 非同步原子落盤 (Write-Through to Disk)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favKey, _memoryFavorites!.toList());
    } catch (e) {
      debugPrint("⚠️ [Rob Pike 倉儲] 最愛狀態磁碟沉積異常: $e");
    }
  }
}