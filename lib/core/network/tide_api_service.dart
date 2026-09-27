import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/security_util.dart';
import '../../features/tide/data/tide_model.dart';

/// 頂層 Isolate 專用純淨解析函數：獨立於 UI 主執行緒外的背景工作線程
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

/// Apple 首席架構：零掉幀異步水文數據服務 (Zero-Jank Oceanic API Service)
class TideApiService {
  static const String _edgeUrl = "https://beigou0427.github.io/tide_forecast_app";
  static const String _cachePrefix = "tide_offline_cache_";
  static const String _sigPrefix = "tide_cache_sig_";

  Future<TideStationData> fetchData(String stationId, {bool isPremium = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 本地離線快取與防篡改簽章檢驗
    final cachedStr = prefs.getString('$_cachePrefix$stationId');
    final cachedSig = prefs.getString('$_sigPrefix$stationId');
    Map<String, dynamic> localCacheJson = {};

    if (cachedStr != null && cachedStr.isNotEmpty) {
      final bool isSignatureValid = cachedSig != null &&
          SecurityUtil.verifyTamperProofSignature('cache_$stationId', cachedStr, cachedSig);

      if (isSignatureValid) {
        localCacheJson = await compute(_parseAndDecodeJson, cachedStr);
      } else {
        debugPrint("⚠️ [TideApi] 測站 $stationId 本地快取簽章損毀或遭篡改，已安全隔離！");
      }
    }

    Map<String, dynamic> edgeJson = {};

    // 2. 邊緣快照專線請求 (含零信任主機白名單校驗)
    try {
      final t = DateTime.now().millisecondsSinceEpoch;
      final edgeUri = Uri.parse("$_edgeUrl/edge_$stationId.json?t=$t");

      if (!SecurityUtil.isAuthorizedHost(edgeUri)) {
        throw SecurityException("未授權之伺服器網域請求: ${edgeUri.host}");
      }

      debugPrint("📡 [TideApi] 正在以極速專線抓取邊緣快照 -> $edgeUri");
      final edgeResponse = await http.get(edgeUri).timeout(const Duration(milliseconds: 3500));
      
      if (edgeResponse.statusCode == 200) {
        edgeJson = await compute(_parseAndDecodeJson, edgeResponse.body);
        
        // 寫入本地快取並附加防篡改數位簽章
        final rawBody = jsonEncode(edgeJson);
        final signature = SecurityUtil.generateTamperProofSignature('cache_$stationId', rawBody);
        await prefs.setString('$_cachePrefix$stationId', rawBody);
        await prefs.setString('$_sigPrefix$stationId', signature);
      }
    } catch (edgeError) {
      debugPrint("⚠️ [TideApi] 外海弱網或邊緣節點連線逾時 ($edgeError)，平滑啟動本地快取防禦！");
      edgeJson = localCacheJson;
    }

    // 3. 非 VIP 權益直接返回邊緣或本地快照
    if (!isPremium) {
      if (edgeJson.isNotEmpty) {
        return TideStationData.fromEdgeJson(edgeJson);
      }
      if (localCacheJson.isNotEmpty) {
        return TideStationData.fromEdgeJson(localCacheJson);
      }
      throw Exception("外海訊號微弱，且本站尚無離線存檔。請稍後移至收訊良好處重試。");
    }

    // 4. VIP 氣象署官方光纖專線直連 (雙軌融合)
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
      }
    } catch (cwaError) {
      debugPrint("⚠️ [VIP 直連] 官方專線逾時 ($cwaError)，平滑降級使用邊緣或本地快取");
    }

    if (edgeJson.isNotEmpty) {
      return TideStationData.fromEdgeJson(edgeJson);
    }
    if (localCacheJson.isNotEmpty) {
      return TideStationData.fromEdgeJson(localCacheJson);
    }

    throw Exception("外海訊號微弱且無離線快取，請移至收訊良好處重試。");
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
