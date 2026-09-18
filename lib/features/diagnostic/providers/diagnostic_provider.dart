import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/constants.dart';

/// 自檢模式狀態提供者
final diagnosticProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  Map<String, String> results = {};

  // 1. 檢查 CWA API 金鑰解密
  try {
    final key = AppConstants.officialApiKey;
    results['CWA 金鑰解密'] = key.startsWith('CWA-') ? '✅ 成功 (${key.substring(0, 8)}...)' : '❌ 格式異常';
  } catch (e) {
    results['CWA 金鑰解密'] = '❌ 錯誤: $e';
  }

  // 2. 檢查 Edge API (GitHub Pages) 連線
  try {
    final edgeUrl = "https://beigou0427.github.io/tide_forecast_app/edge_46694A.json";
    final res = await http.get(Uri.parse(edgeUrl)).timeout(const Duration(seconds: 5));
    results['邊緣節點連線 (Edge)'] = res.statusCode == 200 ? '✅ 正常 (200)' : '❌ 異常 (${res.statusCode})';
  } catch (e) {
    results['邊緣節點連線 (Edge)'] = '❌ 逾時或斷線';
  }

  // 3. 檢查 CWA 官方 API 連線
  try {
    final cwaUrl = "https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-B0075-001?Authorization=${AppConstants.officialApiKey}&StationID=46694A";
    final res = await http.get(Uri.parse(cwaUrl)).timeout(const Duration(seconds: 5));
    results['官方節點連線 (CWA)'] = res.statusCode == 200 ? '✅ 正常 (200)' : '❌ 異常 (${res.statusCode})';
  } catch (e) {
    results['官方節點連線 (CWA)'] = '❌ 逾時或斷線';
  }

  // 4. 檢查 GPS 權限狀態
  try {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission perm = await Geolocator.checkPermission();
    results['GPS 定位服務'] = enabled && (perm == LocationPermission.always || perm == LocationPermission.whileInUse) 
        ? '✅ 已授權' : '⚠️ 未授權或未開啟';
  } catch (e) {
    results['GPS 定位服務'] = '❌ 檢查失敗';
  }

  // 5. 檢查本地存儲與 Pro 狀態
  try {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro') ?? false;
    final favs = prefs.getStringList('favorite_stations_v1') ?? [];
    results['本地存儲狀態'] = '✅ 正常 (Pro: $isPro, 最愛: ${favs.length}筆)';
  } catch (e) {
    results['本地存儲狀態'] = '❌ 讀取失敗';
  }

  return results;
});
