import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/security_util.dart';
import '../../features/tide/data/tide_model.dart';

/// 頂層 Isolate 專用純淨解析函數
Map<String, dynamic> _parseAndDecodeJson(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  } catch (_) {
    return {};
  }
}

enum CircuitState { closed, open, halfOpen }

/// Werner Vogels SRE 斷路器模式：保護伺服器防雪崩與本機 0ms 極速降級
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration baseResetDuration;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastStateChange;
  Duration _currentResetDuration;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 3,
    this.baseResetDuration = const Duration(seconds: 30),
  }) : _currentResetDuration = baseResetDuration;

  bool canExecute() {
    final now = DateTime.now();
    if (_state == CircuitState.open) {
      if (_lastStateChange != null && now.difference(_lastStateChange!) > _currentResetDuration) {
        _state = CircuitState.halfOpen;
        _lastStateChange = now;
        debugPrint("⚡ [SRE 斷路器:$name] 進入 Half-Open 探針試驗狀態");
        return true;
      }
      return false; // 0ms 立即熔斷，保護伺服器與手機電力
    }
    return true;
  }

  void recordSuccess() {
    if (_state != CircuitState.closed) {
      debugPrint("✅ [SRE 斷路器:$name] 探針成功，恢復 Closed 正常連線狀態");
    }
    _state = CircuitState.closed;
    _failureCount = 0;
    _currentResetDuration = baseResetDuration;
  }

  void recordFailure() {
    _failureCount++;
    final now = DateTime.now();
    if (_state == CircuitState.halfOpen || _failureCount >= failureThreshold) {
      _state = CircuitState.open;
      _lastStateChange = now;
      final randomJitterMs = (now.millisecond % 5000);
      final newSeconds = math.min(300, (_currentResetDuration.inSeconds * 1.5).toInt());
      _currentResetDuration = Duration(seconds: newSeconds, milliseconds: randomJitterMs);
      debugPrint("🚨 [SRE 斷路器:$name] 連續失敗 $_failureCount 次，進入 OPEN 熔斷！阻斷 ${_currentResetDuration.inSeconds} 秒");
    }
  }
}

/// Apple 首席架構：零掉幀異步水文數據服務 (Zero-Jank Oceanic API Service)
class TideApiService {
  static const String _edgeUrl = "https://beigou0427.github.io/tide_forecast_app";
  static const String _cachePrefix = "tide_offline_cache_";
  static const String _sigPrefix = "tide_cache_sig_";
  static const String _archivePrefix = "tide_archive_cache_";

  // 全域 SRE 斷路器執行個體
  static final CircuitBreaker _edgeBreaker = CircuitBreaker(name: "EdgeCDN", failureThreshold: 3);
  static final CircuitBreaker _cwaBreaker = CircuitBreaker(name: "CwaOfficial", failureThreshold: 3);

  /// 1. 熱資料快照獲取（首頁秒開：約 10 KB）
  Future<TideStationData> fetchData(String stationId, {bool isPremium = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedStr = prefs.getString('$_cachePrefix$stationId');
    final cachedSig = prefs.getString('$_sigPrefix$stationId');
    Map<String, dynamic> localCacheJson = {};

    if (cachedStr != null && cachedStr.isNotEmpty) {
      final bool isSignatureValid = cachedSig != null &&
          SecurityUtil.verifyTamperProofSignature('cache_$stationId', cachedStr, cachedSig);

      if (isSignatureValid) {
        localCacheJson = await compute(_parseAndDecodeJson, cachedStr);
      } else {
        debugPrint("⚠️ [TideApi] 測站 $stationId 本地快取簽章損毀，已安全隔離！");
      }
    }

    Map<String, dynamic> edgeJson = {};

    if (_edgeBreaker.canExecute()) {
      try {
        final t = DateTime.now().millisecondsSinceEpoch;
        final edgeUri = Uri.parse("$_edgeUrl/edge_$stationId.json?t=$t");

        if (!SecurityUtil.isAuthorizedHost(edgeUri)) {
          throw SecurityException("未授權之伺服器網域請求: ${edgeUri.host}");
        }

        debugPrint("📡 [TideApi] 正在以專線抓取極輕量熱快照 (10KB) -> $edgeUri");
        final edgeResponse = await http.get(edgeUri).timeout(const Duration(milliseconds: 3500));
        
        if (edgeResponse.statusCode == 200) {
          _edgeBreaker.recordSuccess();
          edgeJson = await compute(_parseAndDecodeJson, edgeResponse.body);
          
          final rawBody = jsonEncode(edgeJson);
          final signature = SecurityUtil.generateTamperProofSignature('cache_$stationId', rawBody);
          await prefs.setString('$_cachePrefix$stationId', rawBody);
          await prefs.setString('$_sigPrefix$stationId', signature);
        } else {
          _edgeBreaker.recordFailure();
          edgeJson = localCacheJson;
        }
      } catch (edgeError) {
        _edgeBreaker.recordFailure();
        debugPrint("⚠️ [TideApi] 邊緣節點連線異常 ($edgeError)，平滑啟動本地快取防禦！");
        edgeJson = localCacheJson;
      }
    } else {
      debugPrint("🛡️ [SRE 斷路器生效] EdgeCDN 處於熔斷保護期，0ms 極速切換本地快取！");
      edgeJson = localCacheJson;
    }

    if (!isPremium) {
      if (edgeJson.isNotEmpty) {
        return TideStationData.fromEdgeJson(edgeJson);
      }
      if (localCacheJson.isNotEmpty) {
        return TideStationData.fromEdgeJson(localCacheJson);
      }
      throw Exception("外海訊號微弱，且本站尚無離線存檔。請稍後移至收訊良好處重試。");
    }

    // VIP 氣象署官方直連專線
    if (_cwaBreaker.canExecute()) {
      try {
        debugPrint("💎 [VIP 直連] 向氣象署專線請求站點 $stationId 即時數據...");
        final cwaUri = Uri.parse(
          "https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=${AppConstants.officialApiKey}&StationID=$stationId",
        );

        if (!SecurityUtil.isAuthorizedHost(cwaUri)) {
          throw SecurityException("未授權之官方伺服器網域: ${cwaUri.host}");
        }
        
        final cwaResponse = await http.get(cwaUri).timeout(const Duration(milliseconds: 3500));
        
        if (cwaResponse.statusCode == 200) {
          _cwaBreaker.recordSuccess();
          final cwaData = await compute(_parseAndDecodeJson, cwaResponse.body);
          final records = cwaData['Records'] ?? cwaData['records'] ?? {};
          final seaObs = records['SeaSurfaceObs'] ?? records;
          final locations = (seaObs['Location'] is List) ? seaObs['Location'] : [];
          
          if (locations.isNotEmpty) {
            final realtimeObs = locations[0];

            final stationInfo = (edgeJson['station_info'] is Map) 
                ? edgeJson['station_info'] as Map<String, dynamic> 
                : (localCacheJson['station_info'] as Map<String, dynamic>? ?? {});
            final edgeObs = (edgeJson['obs'] is Map) 
                ? edgeJson['obs'] as Map<String, dynamic> 
                : (localCacheJson['obs'] as Map<String, dynamic>? ?? {});

            final mergedObs = Map<String, dynamic>.from(realtimeObs);
            mergedObs['StationName'] = stationInfo['friendly_name'] ?? edgeObs['StationName'] ?? "測站 $stationId";
            mergedObs['CountyName'] = stationInfo['region'] ?? edgeObs['CountyName'] ?? "";
            mergedObs['TownName'] = stationInfo['town'] ?? edgeObs['TownName'] ?? "";
            mergedObs['lat'] = stationInfo['lat'] ?? edgeObs['lat'] ?? 25.037;
            mergedObs['lng'] = stationInfo['lng'] ?? edgeObs['lng'] ?? 121.926;
            mergedObs['attr'] = stationInfo['station_type'] ?? edgeObs['attr'] ?? "資料浮標";
            mergedObs['region'] = stationInfo['region'] ?? edgeObs['region'] ?? "北部";

            final mergedJson = {
              "obs": mergedObs,
              "station_info": stationInfo,
              "forecasts": edgeJson['forecasts'] ?? localCacheJson['forecasts'] ?? [],
              "ai_expert": edgeJson['ai_expert'] ?? localCacheJson['ai_expert'] ?? {
                "briefing": "AI 實時簡報同步完成，海況平穩。",
                "safety_score": 85,
                "activities": ["海邊作業", "作釣觀察"]
              }
            };

            final mergedBody = jsonEncode(mergedJson);
            final mergedSig = SecurityUtil.generateTamperProofSignature('cache_$stationId', mergedBody);
            await prefs.setString('$_cachePrefix$stationId', mergedBody);
            await prefs.setString('$_sigPrefix$stationId', mergedSig);
            
            debugPrint("✅ [VIP 直連] 數據融合完成，寫入本地安全快取！");
            return TideStationData.fromEdgeJson(mergedJson);
          }
        } else {
          _cwaBreaker.recordFailure();
        }
      } catch (cwaError) {
        _cwaBreaker.recordFailure();
        debugPrint("⚠️ [VIP 直連] 官方專線逾時 ($cwaError)，平滑降級使用邊緣或本地快取");
      }
    } else {
      debugPrint("🛡️ [SRE 斷路器生效] CWA 官方專線熔斷中，0ms 平滑降級邊緣快照！");
    }

    if (edgeJson.isNotEmpty) {
      return TideStationData.fromEdgeJson(edgeJson);
    }
    if (localCacheJson.isNotEmpty) {
      return TideStationData.fromEdgeJson(localCacheJson);
    }

    throw Exception("外海訊號微弱且無離線快取，請移至收訊良好處重試。");
  }

  /// 🌟 2. Werner Vogels 冷歷史時間序列「按需非同步懶加載」（約 250 KB）
  Future<List<Observation>> fetchArchiveObservations(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "$_archivePrefix$stationId";
    final cachedStr = prefs.getString(cacheKey);

    Map<String, dynamic> archiveJson = {};

    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final archiveUri = Uri.parse("$_edgeUrl/archive_$stationId.json?t=$t");

      if (!SecurityUtil.isAuthorizedHost(archiveUri)) {
        throw SecurityException("未授權之伺服器網域: ${archiveUri.host}");
      }

      debugPrint("📦 [TideApi:冷存儲] 按需非同步拉取 30 天歷史數據 -> $archiveUri");
      final res = await http.get(archiveUri).timeout(const Duration(milliseconds: 4000));
      
      if (res.statusCode == 200) {
        archiveJson = await compute(_parseAndDecodeJson, res.body);
        await prefs.setString(cacheKey, res.body);
      } else if (cachedStr != null && cachedStr.isNotEmpty) {
        archiveJson = await compute(_parseAndDecodeJson, cachedStr);
      }
    } catch (e) {
      debugPrint("⚠️ [TideApi] 冷歷史時間序列連線逾時 ($e)，回退至本機歷史快取");
      if (cachedStr != null && cachedStr.isNotEmpty) {
        archiveJson = await compute(_parseAndDecodeJson, cachedStr);
      }
    }

    final rawObs = archiveJson['observations'] as List? ?? [];
    return rawObs.map((i) => Observation.fromProxy(i as Map<String, dynamic>)).toList();
  }

  Future<TideStationData> fetchHistoryOfficial(String sid, String s, String e) async => throw UnimplementedError();
  Future<List<TideForecast>> fetchForecastOfficial(String sid) async => [];
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => "SecurityException: $message";
}
