import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tide/data/tide_model.dart';

class CachedTensorNode {
  final String fingerprint;
  final TideStationData data;
  final DateTime cachedAt;
  DateTime lastAccessed;

  CachedTensorNode({
    required this.fingerprint,
    required this.data,
    required this.cachedAt,
    required this.lastAccessed,
  });

  /// 海事水文即時性防護：超過 6 小時視為陳舊數據
  bool isExpired({Duration maxTtl = const Duration(hours: 6)}) {
    return DateTime.now().difference(cachedAt) > maxTtl;
  }
}

final tensorCacheManagerProvider = Provider<TensorCacheManager>((ref) {
  return TensorCacheManager();
});

/// 🌟 Jeff Dean (Google Chief Scientist) 端側內容定址張量快取管理器
/// 升級海事時效看門狗 (TTL) 與並發安全 LRU 淘汰演算法，杜絕陳舊水文與 OOM
class TensorCacheManager {
  static const int _maxCapacity = 30; // 常駐最多 30 席測站記憶體實體，杜絕駕駛台發熱與 OOM
  final Map<String, CachedTensorNode> _cachePool = {};

  /// 🌟 檢驗指紋與時效性並命中快取實體 (0ms 零解析開銷)
  TideStationData? getIfFingerprintMatches(String stationId, String currentFingerprint) {
    final node = _cachePool[stationId];
    if (node == null) return null;

    // 時態防禦：即使指紋相同，若超出 6 小時海事生命週期則強制失效
    if (node.isExpired()) {
      _cachePool.remove(stationId);
      debugPrint("⏳ [張量快取 TTL 看門狗] 測站 $stationId 快取超出 6 小時海事時效，安全失效淘汰");
      return null;
    }

    if (node.fingerprint == currentFingerprint) {
      node.lastAccessed = DateTime.now();
      debugPrint("⚡ [張量快取命中] 測站 $stationId 特徵指紋精確命中 ($currentFingerprint)，0ms 復用實體");
      return node.data;
    }

    debugPrint("🔄 [張量快取特徵漂移] 測站 $stationId (${node.fingerprint} -> $currentFingerprint)，安排更新");
    return null;
  }

  /// 寫入快取並執行並發安全 LRU 淘汰演算法
  void put(String stationId, String fingerprint, TideStationData data) {
    if (_cachePool.length >= _maxCapacity && !_cachePool.containsKey(stationId)) {
      String? oldestKey;
      DateTime oldestTime = DateTime.now();

      // 快照安全複製鍵名，杜絕 ConcurrentModificationException
      final keysSnapshot = _cachePool.keys.toList();
      for (final key in keysSnapshot) {
        final node = _cachePool[key];
        if (node != null && node.lastAccessed.isBefore(oldestTime)) {
          oldestTime = node.lastAccessed;
          oldestKey = key;
        }
      }

      if (oldestKey != null) {
        _cachePool.remove(oldestKey);
        debugPrint("🧹 [LRU 記憶體收割] 淘汰最久未存取測站快取: $oldestKey");
      }
    }

    _cachePool[stationId] = CachedTensorNode(
      fingerprint: fingerprint,
      data: data,
      cachedAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );
  }

  /// 獲取直接記憶體實體 (受時效約束)
  TideStationData? getDirect(String stationId) {
    final node = _cachePool[stationId];
    if (node != null) {
      if (node.isExpired()) {
        _cachePool.remove(stationId);
        return null;
      }
      node.lastAccessed = DateTime.now();
      return node.data;
    }
    return null;
  }

  void clear() {
    _cachePool.clear();
  }

  int get cachedStationCount => _cachePool.length;
}